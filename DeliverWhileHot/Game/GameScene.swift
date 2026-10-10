//
//  GameScene.swift
//  DeliverWhileHot
//

import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private enum EndingSequencePhase: Equatable {
        case inactive, approach, preparePrompt, preparing, jumpPrompt, successFlight, failedCrash, exploding
    }

    private static let preparePromptDuration: TimeInterval = 2.1
    private static let jumpPromptDuration: TimeInterval = 1.55
    private static let endingPromptWindow: CGFloat = 0.08
    private static let jumpPromptTimeout: TimeInterval =
        jumpPromptDuration * (1 + 2 * TimeInterval(endingPromptWindow))

    private let nodeFactory = GameNodeFactory()
    private let worldNode = SKNode()
    private let encounterNodeLayer = SKNode()
    private let gameplayCamera = SKCameraNode()
    private var player = PlayerNode()
    private var horizontalInput: CGFloat = 0
    private var verticalInput: CGFloat = 0
    private var playerVelocity = CGVector.zero
    private var lastMovementDirection = CGVector(dx: 0, dy: 1)
    private var routeWidth: CGFloat = 0
    private var navigableWidth: CGFloat = 0
    private var routeHeight: CGFloat = 0
    private var lastUpdateTime: TimeInterval?
    private var lastCollisionTime: TimeInterval = -.infinity
    private var hasReachedDestination = false
    private var isConfigured = false
    private var elapsedStageTime: TimeInterval = 0
    private var freezeRemaining: TimeInterval = 0
    private var slowMotionRemaining: TimeInterval = 0
    private var blockStartedAt: TimeInterval = -.infinity
    private var lastBlockImpactTime: TimeInterval = -.infinity
    private var didParryDuringCurrentBlock = false
    private var lastEatTime: TimeInterval = -.infinity
    private var lastMolotovTime: TimeInterval = -.infinity
    private var molotovCount = GameConstants.startingMolotovCount
    private var didSpawnThief = false
    private var didSpawnPidgeot = false
    private var hazardSpawnTimer: TimeInterval = 0
    private var hazardSpawnIndex = 0
    private(set) var gameState = GameState()
    private var onStateChanged: ((GameState) -> Void)?
    private var onFinished: ((GameEndReason) -> Void)?
    private var onEndingPromptChanged: ((EndingPromptStep?, CGFloat) -> Void)?
    private var endingSequencePhase = EndingSequencePhase.inactive
    private var endingPromptStep: EndingPromptStep?
    private var endingPromptElapsed: TimeInterval = 0
    private var endingPromptStartProgress: CGFloat = 0.5
    private var endingSetpiece: EndingSetpieceNode?
    private var endingPreparationNode: SKSpriteNode?

    func configure(for viewSize: CGSize,
                   onStateChanged: ((GameState) -> Void)? = nil,
                   onFinished: ((GameEndReason) -> Void)? = nil,
                   onEndingPromptChanged: ((EndingPromptStep?, CGFloat) -> Void)? = nil) {
        guard !isConfigured, viewSize.width > 0, viewSize.height > 0 else { return }
        isConfigured = true
        GameSpriteSheet.prepareEncounterFrames()
        self.onStateChanged = onStateChanged
        self.onFinished = onFinished
        self.onEndingPromptChanged = onEndingPromptChanged

        let playerStartY = viewSize.height * 0.22
        let collisionPadding = GameConstants.playerSize.height / 2 +
            GameConstants.destinationHeight / 2
        let targetTravelDistance = GameConstants.automaticScrollSpeed *
            CGFloat(GameConstants.targetStageDuration)
        let targetRouteHeight = targetTravelDistance +
            GameConstants.destinationTopInset +
            playerStartY +
            collisionPadding
        routeHeight = max(targetRouteHeight, GameConstants.minimumRouteHeight)
        size = viewSize
        scaleMode = .aspectFill
        backgroundColor = GameConstants.routeColor
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        routeWidth = min(viewSize.width * GameConstants.routeWidthRatio,
                         GameConstants.maximumRouteWidth)
        navigableWidth = viewSize.width * GameConstants.navigableWidthRatio
        addChild(worldNode)
        addChild(encounterNodeLayer)
        camera = gameplayCamera
        gameplayCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gameplayCamera)
        worldNode.zPosition = 0
        encounterNodeLayer.zPosition = 10

        worldNode.addChild(nodeFactory.makeRoad(sceneWidth: size.width,
                                                roadWidth: routeWidth,
                                                height: routeHeight))
        nodeFactory.makeRoadsideStrips(width: size.width,
                                       routeWidth: routeWidth,
                                       height: routeHeight).forEach(worldNode.addChild)
        let sectionHeight: CGFloat = 520
        let sectionCount = Int(ceil(routeHeight / sectionHeight))
        for index in 0..<sectionCount {
            let section = StageSectionNode(index: index,
                                           width: size.width,
                                           routeWidth: routeWidth,
                                           sectionHeight: sectionHeight)
            section.position.y = CGFloat(index) * sectionHeight
            worldNode.addChild(section)
        }
        nodeFactory.makeLaneMarkers(width: size.width, height: routeHeight).forEach(worldNode.addChild)
        worldNode.addChild(nodeFactory.makeDestination(width: size.width, routeWidth: routeWidth, height: routeHeight))
        let rightRoadEdge = size.width / 2 + routeWidth / 2
        worldNode.addChild(nodeFactory.makeBonus(
            kind: .foodSteal,
            position: CGPoint(x: rightRoadEdge - 10,
                              y: routeHeight * 0.36)
        ))
        player = nodeFactory.makePlayer()
        player.position = CGPoint(x: size.width / 2, y: viewSize.height * 0.22)
        player.zPosition = 20
        addChild(player)
        publishState()
    }

    override func update(_ currentTime: TimeInterval) {
        guard isConfigured else { return }
        let deltaTime = min(currentTime - (lastUpdateTime ?? currentTime), 1.0 / 20.0)
        lastUpdateTime = currentTime

        if endingSequencePhase != .inactive && endingSequencePhase != .approach {
            updateEndingSequence(deltaTime: deltaTime)
            return
        }

        guard !hasReachedDestination, case .playing = gameState.phase else { return }

        if freezeRemaining > 0 {
            freezeRemaining = max(0, freezeRemaining - deltaTime)
            if freezeRemaining == 0 {
                endFreeze()
            }
            return
        }

        var gameplayDeltaTime = deltaTime
        if slowMotionRemaining > 0 {
            slowMotionRemaining = max(0, slowMotionRemaining - deltaTime)
            gameplayDeltaTime *= GameConstants.parrySlowMotionFactor
            if slowMotionRemaining == 0 {
                endSlowMotion()
            }
        }

        let destinationDistance = nextDestinationDistanceAhead
        if endingSequencePhase == .inactive && destinationDistance <= GameConstants.endingApproachDistance {
            beginEndingApproach()
        }
        let approachAmount = min(1, max(0, (720 - destinationDistance) / 720))
        let approachEase = approachAmount * approachAmount * (3 - 2 * approachAmount)
        let worldDeltaTime = gameplayDeltaTime * TimeInterval(1 - 0.38 * approachEase)

        GameRules.advanceTemperature(&gameState, by: gameplayDeltaTime)
        if gameState.foodTemperature <= 0 {
            finish(with: .foodTooCold)
            return
        }

        elapsedStageTime += gameplayDeltaTime
        if endingSequencePhase != .approach {
            updateWorldHazards(deltaTime: worldDeltaTime)
            updateEncounters(deltaTime: worldDeltaTime)
            updateMolotovProjectiles(deltaTime: worldDeltaTime)
        }

        worldNode.position.y -= GameConstants.automaticScrollSpeed * CGFloat(worldDeltaTime)
        if endingSequencePhase == .approach {
            endingSetpiece?.position.y -= GameConstants.automaticScrollSpeed * CGFloat(worldDeltaTime)
            if endingWallDistanceAhead <= GameConstants.endingPromptDistance {
                beginEndingTimingChallenge()
                publishState()
                return
            }
        }
        if worldNode.position.y <= -routeHeight {
            if endingSequencePhase == .approach {
                beginEndingTimingChallenge()
            } else {
                beginEndingApproach()
                beginEndingTimingChallenge()
            }
            return
        }

        for hazard in worldNode.children.compactMap({ $0 as? HazardNode }) {
            hazard.updateBehavior(deltaTime: gameplayDeltaTime,
                                  routeWidth: routeWidth,
                                  sceneWidth: size.width,
                                  screenY: hazard.position.y + worldNode.position.y,
                                  playerY: player.position.y)
        }

        let movementMultiplier: CGFloat = player.isThrowing ? 0 : (player.isEating ? 0.45 : 1.0)
        player.setMovement(horizontal: horizontalInput, vertical: verticalInput)
        player.updateMovement(deltaTime: deltaTime)
        let targetVelocity = CGVector(
            dx: horizontalInput * GameConstants.playerMovementSpeed * movementMultiplier,
            dy: verticalInput * GameConstants.playerVerticalMovementSpeed * movementMultiplier
        )
        if movementMultiplier == 0 {
            playerVelocity = .zero
        } else {
            let response = CGFloat(1 - exp(-deltaTime / GameConstants.movementSmoothing))
            playerVelocity.dx += (targetVelocity.dx - playerVelocity.dx) * response
            playerVelocity.dy += (targetVelocity.dy - playerVelocity.dy) * response
        }
        player.position.x += playerVelocity.dx * CGFloat(deltaTime)
        player.position.y += playerVelocity.dy * CGFloat(deltaTime)

        let halfNavigableArea = navigableWidth / 2 - GameConstants.playerSize.width / 2 - 8
        player.position.x = min(max(player.position.x, size.width / 2 - halfNavigableArea),
                                size.width / 2 + halfNavigableArea)

        let minimumPlayerY = GameConstants.bottomTouchExclusionHeight + GameConstants.playerSize.height / 2 + 12
        let maximumPlayerY = size.height - GameConstants.topTouchExclusionHeight - GameConstants.playerSize.height / 2 - 12
        player.position.y = min(max(player.position.y, minimumPlayerY), maximumPlayerY)
        keepPlayerAwayFromJoystick()

        checkSceneInteractions(at: currentTime)
        publishState()
    }

    func movePlayer(direction: CGFloat) {
        guard !hasReachedDestination, case .playing = gameState.phase else { return }
        horizontalInput = direction
    }

    func setPlayerInput(horizontal: CGFloat, vertical: CGFloat) {
        guard !hasReachedDestination, case .playing = gameState.phase else { return }
        horizontalInput = max(-1, min(1, horizontal))
        verticalInput = max(-1, min(1, vertical))
        let magnitude = hypot(horizontalInput, verticalInput)
        if magnitude > 0.12 {
            lastMovementDirection = CGVector(dx: horizontalInput / magnitude,
                                             dy: verticalInput / magnitude)
        }
        player.setMovement(horizontal: horizontalInput, vertical: verticalInput)
    }

    func stopPlayerMovement() {
        horizontalInput = 0
    }

    func movePlayerVertically(direction: CGFloat) {
        guard !hasReachedDestination, case .playing = gameState.phase else { return }
        verticalInput = direction
    }

    func stopPlayerVerticalMovement() {
        verticalInput = 0
    }

    func throwMolotov() {
        let currentTime = lastUpdateTime ?? 0
        guard !hasReachedDestination,
              case .playing = gameState.phase,
              !player.isEating,
              !player.isThrowing,
              molotovCount > 0,
              currentTime - lastMolotovTime >= GameConstants.molotovCooldown else { return }

        let direction = lastMovementDirection
        guard player.startThrowing(onRelease: { [weak self] in
            guard let self else { return }
            self.molotovCount = max(0, self.molotovCount - 1)
            self.lastMolotovTime = self.lastUpdateTime ?? currentTime
            let startPosition = CGPoint(
                x: self.player.position.x + direction.dx * 42,
                y: self.player.position.y + direction.dy * 42
            )
            let velocity = CGVector(
                dx: direction.dx * GameConstants.molotovProjectileSpeed,
                dy: direction.dy * GameConstants.molotovProjectileSpeed
            )
            self.encounterNodeLayer.addChild(
                MolotovProjectileNode(position: startPosition, velocity: velocity)
            )
            self.publishState()
        }) else { return }
        publishState()
    }

    func setBlocking(_ blocking: Bool) {
        guard !hasReachedDestination, case .playing = gameState.phase else { return }

        if blocking {
            guard !player.isBlocking else { return }
            guard player.startBlocking() else { return }
            blockStartedAt = lastUpdateTime ?? 0
            didParryDuringCurrentBlock = false
        } else {
            player.stopBlocking()
            blockStartedAt = -.infinity
            didParryDuringCurrentBlock = false
        }
    }

    var canThrowMolotov: Bool {
        let currentTime = lastUpdateTime ?? 0
        guard case .playing = gameState.phase else { return false }
        return !player.isEating &&
            !player.isThrowing &&
            molotovCount > 0 &&
            currentTime - lastMolotovTime >= GameConstants.molotovCooldown
    }

    var availableMolotovs: Int {
        molotovCount
    }

    var canEat: Bool {
        let currentTime = lastUpdateTime ?? 0
        guard case .playing = gameState.phase else { return false }
        return !player.isEating &&
            gameState.health < GameState.maximumHealth &&
            gameState.foodRemaining >= GameRules.foodCostPerMeal &&
            currentTime - lastEatTime >= GameConstants.eatCooldown
    }

    var eatCooldownProgress: CGFloat {
        cooldownProgress(since: lastEatTime, duration: GameConstants.eatCooldown)
    }

    var molotovCooldownProgress: CGFloat {
        cooldownProgress(since: lastMolotovTime, duration: GameConstants.molotovCooldown)
    }

    private func cooldownProgress(since startTime: TimeInterval,
                                  duration: TimeInterval) -> CGFloat {
        let currentTime = lastUpdateTime ?? 0
        guard startTime.isFinite else { return 1 }
        return min(1, max(0, CGFloat((currentTime - startTime) / duration)))
    }

    private func checkSceneInteractions(at time: TimeInterval) {
        let playerCenter = player.position
        let playerHalfWidth = GameConstants.playerSize.width / 2
        let playerHalfHeight = GameConstants.playerSize.height / 2

        for hazard in worldNode.children.compactMap({ $0 as? HazardNode }) {
            let hazardCenter = CGPoint(x: hazard.position.x + worldNode.position.x,
                                       y: hazard.position.y + worldNode.position.y)
            let horizontalDistance = abs(playerCenter.x - hazardCenter.x)
            let verticalDistance = abs(playerCenter.y - hazardCenter.y)
            let hazardHalfWidth = hazard.definition.size.width / 2
            let hazardHalfHeight = hazard.definition.size.height / 2
            let isOverlapping = horizontalDistance <= playerHalfWidth + hazardHalfWidth &&
                verticalDistance <= playerHalfHeight + hazardHalfHeight

            if isOverlapping {
                handleObstacleContact(at: time, hazardKind: hazard.definition.kind)
                hazard.removeFromParent()
                break
            }
        }

        for bonus in worldNode.children.compactMap({ $0 as? BonusNode }) {
            let bonusCenter = CGPoint(x: bonus.position.x + worldNode.position.x,
                                      y: bonus.position.y + worldNode.position.y)
            let horizontalDistance = abs(playerCenter.x - bonusCenter.x)
            let verticalDistance = abs(playerCenter.y - bonusCenter.y)
            let isOverlapping = horizontalDistance <= playerHalfWidth + bonus.size.width / 2 &&
                verticalDistance <= playerHalfHeight + bonus.size.height / 2

            if isOverlapping {
                handleBonusCollection(bonus)
            }
        }

        for encounter in encounterNodeLayer.children.compactMap({ $0 as? EncounterNode }) {
            let encounterCenter = encounter.position
            let horizontalDistance = abs(playerCenter.x - encounterCenter.x)
            let verticalDistance = abs(playerCenter.y - encounterCenter.y)
            let isOverlapping = horizontalDistance <= playerHalfWidth + 32 &&
                verticalDistance <= playerHalfHeight + 40

            if isOverlapping {
                handleObstacleContact(at: time)
                encounter.removeFromParent()
            }
        }

        for projectile in encounterNodeLayer.children.compactMap({ $0 as? ProjectileNode }) {
            let horizontalDistance = abs(playerCenter.x - projectile.position.x)
            let verticalDistance = abs(playerCenter.y - projectile.position.y)
            if horizontalDistance <= playerHalfWidth + projectile.hitRadius &&
                verticalDistance <= playerHalfHeight + projectile.hitRadius {
                if player.isBlocking {
                    let blockResult = handleBlockedHit(at: time)
                    if blockResult == .parried && projectile.effect != .spoilFood {
                        projectile.reflect()
                    } else {
                        projectile.removeFromParent()
                    }
                    continue
                }
                projectile.removeFromParent()
                switch projectile.effect {
                case .knifeDamage:
                    handleObstacleContact(at: time)
                case .burningDamage:
                    explodeMolotov(at: player.position)
                    handleObstacleContact(at: time, startsBurning: true)
                case .spoilFood:
                    handlePidgeotMess(at: time)
                }
            }
        }

        for projectile in encounterNodeLayer.children.compactMap({ $0 as? ProjectileNode })
            where projectile.isReflected {
            for hazard in worldNode.children.compactMap({ $0 as? HazardNode }) {
                let hazardCenter = CGPoint(x: hazard.position.x + worldNode.position.x,
                                           y: hazard.position.y + worldNode.position.y)
                let horizontalDistance = abs(projectile.position.x - hazardCenter.x)
                let verticalDistance = abs(projectile.position.y - hazardCenter.y)
                let hazardHalfWidth = hazard.definition.size.width / 2
                let hazardHalfHeight = hazard.definition.size.height / 2
                let didHitHazard = horizontalDistance <= hazardHalfWidth + 12 &&
                    verticalDistance <= hazardHalfHeight + 12

                if didHitHazard {
                    let impactPosition = CGPoint(x: hazardCenter.x,
                                                  y: hazardCenter.y)
                    hazard.removeFromParent()
                    projectile.removeFromParent()
                    encounterNodeLayer.addChild(ParryEffectNode(position: impactPosition))
                    run(.playSoundFileNamed(GameConstants.blockImpactSoundName,
                                            waitForCompletion: false),
                        withKey: "reflectedImpactSound")
                    break
                }
            }

            guard projectile.parent != nil else { continue }

            for encounter in encounterNodeLayer.children.compactMap({ $0 as? EncounterNode })
                where encounter.kind == .thief || encounter.kind == .pidgeot {
                let horizontalDistance = abs(projectile.position.x - encounter.position.x)
                let verticalDistance = abs(projectile.position.y - encounter.position.y)
                let didHitEncounter = horizontalDistance <= 42 && verticalDistance <= 42

                if didHitEncounter {
                    let impactPosition = encounter.position
                    encounter.removeFromParent()
                    projectile.removeFromParent()
                    encounterNodeLayer.addChild(ParryEffectNode(position: impactPosition))
                    run(.playSoundFileNamed(GameConstants.blockImpactSoundName,
                                            waitForCompletion: false),
                        withKey: "reflectedImpactSound")
                    break
                }
            }
        }

        for molotov in encounterNodeLayer.children.compactMap({ $0 as? MolotovProjectileNode }) {
            var didImpact = false

            for hazard in worldNode.children.compactMap({ $0 as? HazardNode }) {
                let hazardCenter = CGPoint(x: hazard.position.x + worldNode.position.x,
                                           y: hazard.position.y + worldNode.position.y)
                let horizontalDistance = abs(molotov.position.x - hazardCenter.x)
                let verticalDistance = abs(molotov.position.y - hazardCenter.y)
                let hazardHalfWidth = hazard.definition.size.width / 2
                let hazardHalfHeight = hazard.definition.size.height / 2

                if horizontalDistance <= hazardHalfWidth + 14 &&
                    verticalDistance <= hazardHalfHeight + 14 {
                    hazard.removeFromParent()
                    didImpact = true
                    break
                }
            }

            if didImpact {
                explodeMolotov(at: molotov.position)
                molotov.removeFromParent()
                continue
            }

            for encounter in encounterNodeLayer.children.compactMap({ $0 as? EncounterNode }) {
                guard encounter.kind == .thief || encounter.kind == .pidgeot else { continue }
                let horizontalDistance = abs(molotov.position.x - encounter.position.x)
                let verticalDistance = abs(molotov.position.y - encounter.position.y)
                if horizontalDistance <= 42 && verticalDistance <= 42 {
                    encounter.removeFromParent()
                    molotov.removeFromParent()
                    explodeMolotov(at: molotov.position)
                    didImpact = true
                    break
                }
            }

            if didImpact { continue }

            let leftWall = size.width / 2 - navigableWidth / 2
            let rightWall = size.width / 2 + navigableWidth / 2
            let reachedWall = molotov.position.x <= leftWall + 8 ||
                molotov.position.x >= rightWall - 8
            if reachedWall {
                molotov.removeFromParent()
                explodeMolotov(at: molotov.position)
            }
        }

        guard let destination = worldNode.childNode(withName: "destination") else { return }
        let destinationCenter = destination.convert(CGPoint.zero, to: self)
        let destinationHalfWidth = (routeWidth - 36) / 2
        let destinationHalfHeight = GameConstants.destinationHeight / 2
        let reachedDestination = abs(playerCenter.x - destinationCenter.x) <= playerHalfWidth + destinationHalfWidth &&
            abs(playerCenter.y - destinationCenter.y) <= playerHalfHeight + destinationHalfHeight

        if reachedDestination {
            if endingSequencePhase == .approach {
                beginEndingTimingChallenge()
            } else {
                beginEndingApproach(distanceAhead: max(GameConstants.endingPromptDistance,
                                                       nextDestinationDistanceAhead))
                beginEndingTimingChallenge()
            }
        }
    }

    private func keepPlayerAwayFromJoystick() {
        let visualHalfWidth = player.frame.width / 2
        let visualHalfHeight = player.frame.height / 2
        let isNearJoystick = player.position.x - visualHalfWidth < GameConstants.joystickSafeZoneRightEdge &&
            player.position.y - visualHalfHeight < GameConstants.joystickSafeZoneTopEdge

        guard isNearJoystick else { return }

        let safeX = GameConstants.joystickSafeZoneRightEdge + visualHalfWidth + 12
        let halfNavigableArea = navigableWidth / 2 - GameConstants.playerSize.width / 2 - 8
        player.position.x = min(safeX, size.width / 2 + halfNavigableArea)
    }

    private enum BlockResult: Equatable {
        case blocked
        case parried
    }

    private func handleObstacleContact(at time: TimeInterval,
                                      startsBurning: Bool = false,
                                      hazardKind: HazardKind? = nil) {
        if player.isBlocking {
            handleBlockedHit(at: time)
            return
        }

        guard time - lastCollisionTime >= GameConstants.hitInvincibilityDuration else { return }
        lastCollisionTime = time

        if startsBurning {
            player.setBurning(true)
        }
        player.playHitAnimation()
        run(.playSoundFileNamed(GameConstants.hitSoundName, waitForCompletion: false),
            withKey: "hitSound")
        beginFreeze(for: GameConstants.hitStopDuration)
        GameRules.applyObstacleDamage(&gameState)
        if gameState.health <= 0 {
            finish(with: .healthDepleted)
        }
        publishState()
    }

    @discardableResult
    private func handleBlockedHit(at time: TimeInterval) -> BlockResult {
        guard player.isBlocking else { return .blocked }

        let isPerfectParry = !didParryDuringCurrentBlock &&
            time - blockStartedAt <= GameConstants.perfectParryWindow

        if isPerfectParry {
            didParryDuringCurrentBlock = true
            lastCollisionTime = time
            encounterNodeLayer.addChild(ParryEffectNode(position: player.position))
            run(.playSoundFileNamed(GameConstants.parrySoundName,
                                    waitForCompletion: false),
                withKey: "parrySound")
            beginSlowMotion(for: GameConstants.parrySlowMotionDuration)
            return .parried
        }

        guard time - lastBlockImpactTime >= GameConstants.blockImpactCooldown else {
            return .blocked
        }

        guard time - lastCollisionTime >= GameConstants.collisionCooldown else {
            return .blocked
        }

        lastBlockImpactTime = time
        lastCollisionTime = time
        GameRules.applyBlockedHitFoodLoss(&gameState)
        run(.playSoundFileNamed(GameConstants.blockImpactSoundName,
                                waitForCompletion: false),
            withKey: "blockImpactSound")
        publishState()
        return .blocked
    }

    private func handlePidgeotMess(at time: TimeInterval) {
        guard time - lastCollisionTime >= GameConstants.collisionCooldown else { return }
        lastCollisionTime = time
        GameRules.applyPidgeotMess(&gameState)
        publishState()
    }

    private func handleBonusCollection(_ bonus: BonusNode) {
        guard case .playing = gameState.phase,
              !bonus.isCollected else { return }
        beginFreeze(for: GameConstants.bonusStopDuration)
        run(.playSoundFileNamed(GameConstants.bonusPickupSoundName,
                                waitForCompletion: false))

        switch bonus.kind {
        case .foodSteal:
            GameRules.applyPizzaStealBonus(&gameState)
        }

        if bonus.kind == .foodSteal {
            bonus.collect()
        }
        publishState()
    }

    func consumeFood() {
        let currentTime = lastUpdateTime ?? 0
        guard !hasReachedDestination, canEat else { return }
        guard GameRules.consumeFood(&gameState) else { return }
        lastEatTime = currentTime
        run(.playSoundFileNamed(GameConstants.healthRecoverySoundName,
                                waitForCompletion: false),
            withKey: "healthRecoverySound")
        player.playHealthRecoveryAnimation()
        if player.startEating() {
            publishState()
        }
    }

    private func playMolotovImpactSound() {
        run(.sequence([
            .playSoundFileNamed(GameConstants.molotovGlassSoundName,
                                waitForCompletion: false),
            .wait(forDuration: 0.08),
            .playSoundFileNamed(GameConstants.molotovExplosionSoundName,
                                waitForCompletion: false)
        ]))
    }

    private func explodeMolotov(at position: CGPoint) {
        encounterNodeLayer.addChild(MolotovExplosionNode(position: position))
        playMolotovImpactSound()
    }

    private func beginFreeze(for duration: TimeInterval) {
        freezeRemaining = max(freezeRemaining, duration)
        worldNode.speed = 0
        encounterNodeLayer.speed = 0
        player.speed = 0
        physicsWorld.speed = 0
    }

    private func beginSlowMotion(for duration: TimeInterval) {
        slowMotionRemaining = max(slowMotionRemaining, duration)
        worldNode.speed = GameConstants.parrySlowMotionFactor
        encounterNodeLayer.speed = GameConstants.parrySlowMotionFactor
        player.speed = GameConstants.parrySlowMotionFactor
        physicsWorld.speed = GameConstants.parrySlowMotionFactor
    }

    private func endSlowMotion() {
        worldNode.speed = 1
        encounterNodeLayer.speed = 1
        player.speed = 1
        physicsWorld.speed = 1
    }

    private func endFreeze() {
        worldNode.speed = 1
        encounterNodeLayer.speed = 1
        player.speed = 1
        physicsWorld.speed = 1
    }

    var isEating: Bool {
        player.isEating
    }

    private func finish(with reason: GameEndReason) {
        guard case .playing = gameState.phase else { return }
        endingPromptStep = nil
        onEndingPromptChanged?(nil, 0)
        gameState.phase = .ended(reason)
        hasReachedDestination = true
        horizontalInput = 0
        verticalInput = 0
        worldNode.removeAllActions()
        player.stopAnimations()
        publishState()
        onFinished?(reason)
    }

    private var endingPromptProgress: CGFloat {
        let duration = endingSequencePhase == .jumpPrompt
            ? Self.jumpPromptDuration
            : Self.preparePromptDuration
        // Keep the displayed angle unwrapped so the marker moves forward through
        // twelve o'clock instead of jumping from one turn back to zero.
        return endingPromptStartProgress + CGFloat(endingPromptElapsed / duration)
    }

    private var endingWallDistanceAhead: CGFloat {
        guard let endingSetpiece else { return .greatestFiniteMagnitude }
        let wallCenter = endingSetpiece.convert(
            CGPoint(x: size.width / 2, y: endingSetpiece.wallCenterY),
            to: self
        )
        return wallCenter.y - player.position.y
    }

    private func beginEndingApproach(distanceAhead: CGFloat? = nil) {
        guard endingSequencePhase == .inactive else { return }
        endingSequencePhase = .approach
        worldNode.children
            .filter { $0 is HazardNode || $0 is BonusNode }
            .forEach { $0.removeFromParent() }
        encounterNodeLayer.removeAllChildren()
        worldNode.childNode(withName: "destination")?.isHidden = true

        let setpiece = EndingSetpieceNode(sceneSize: size, roadWidth: routeWidth)
        let alignedDistance = distanceAhead ?? nextDestinationDistanceAhead
        setpiece.position.y = player.position.y + alignedDistance - setpiece.wallCenterY
        endingSetpiece = setpiece
        addChild(setpiece)

        let doorPoint = setpiece.convert(setpiece.doorTarget, to: self)
        let focusPoint = CGPoint(x: size.width / 2 + (doorPoint.x - size.width / 2) * 0.16,
                                 y: size.height / 2 + (doorPoint.y - size.height / 2) * 0.08)
        gameplayCamera.run(.group([
            .move(to: focusPoint, duration: 1.15),
            .scale(to: 1.035, duration: 1.15)
        ]), withKey: "endingDoorFocus")
    }

    private func beginEndingTimingChallenge() {
        guard endingSequencePhase == .approach || endingSequencePhase == .inactive else { return }
        if endingSetpiece == nil {
            beginEndingApproach(distanceAhead: max(GameConstants.endingPromptDistance,
                                                   nextDestinationDistanceAhead))
        }
        hasReachedDestination = true
        horizontalInput = 0
        verticalInput = 0
        playerVelocity = .zero
        player.physicsBody = nil
        player.stopAnimations()
        player.isHidden = true
        let preparation = SKSpriteNode(texture: GameSpriteSheet.endingPreparationFrames[0])
        preparation.name = "endingPreparationRider"
        preparation.size = CGSize(width: 66, height: 132)
        preparation.position = player.position
        preparation.zPosition = 30
        addChild(preparation)
        endingPreparationNode = preparation
        worldNode.speed = 0
        encounterNodeLayer.speed = 0
        gameplayCamera.removeAction(forKey: "endingDoorFocus")
        if let endingSetpiece {
            let doorPoint = endingSetpiece.convert(endingSetpiece.doorTarget, to: self)
            let focusPoint = CGPoint(x: size.width / 2 + (doorPoint.x - size.width / 2) * 0.18,
                                     y: size.height / 2 + (doorPoint.y - size.height / 2) * 0.10)
            gameplayCamera.run(.group([
                .move(to: focusPoint, duration: 0.4),
                .scale(to: 1.045, duration: 0.4)
            ]), withKey: "endingDoorFocus")
        }
        showEndingPrompt(.prepare, phase: .preparePrompt)
    }

    private var nextDestinationDistanceAhead: CGFloat {
        guard let destination = worldNode.childNode(withName: "destination") else { return .greatestFiniteMagnitude }
        let point = destination.convert(CGPoint.zero, to: self)
        return point.y - player.position.y
    }

    private func showEndingPrompt(_ step: EndingPromptStep, phase: EndingSequencePhase) {
        // Carry the marker's unwrapped angle into Jump so the faster sweep starts
        // exactly where Prepare finished.
        let carriedProgress = endingPromptProgress
        endingSequencePhase = phase
        endingPromptStep = step
        endingPromptElapsed = 0
        endingPromptStartProgress = step == .prepare ? 0.5 : carriedProgress
        onEndingPromptChanged?(step, endingPromptProgress)
    }

    private func updateEndingSequence(deltaTime: TimeInterval) {
        switch endingSequencePhase {
        case .preparePrompt, .jumpPrompt:
            endingPromptElapsed += deltaTime
            let timeout = endingSequencePhase == .jumpPrompt
                ? Self.jumpPromptTimeout
                : Self.preparePromptDuration
            guard endingPromptElapsed < timeout else {
                beginFailedEnding()
                return
            }
            onEndingPromptChanged?(endingPromptStep, endingPromptProgress)
        case .inactive, .approach, .preparing, .successFlight, .failedCrash, .exploding:
            break
        }
    }

    func submitEndingPromptTap() {
        guard endingSequencePhase == .preparePrompt || endingSequencePhase == .jumpPrompt else { return }
        let progress = endingPromptProgress.truncatingRemainder(dividingBy: 1)
        guard progress <= Self.endingPromptWindow || progress >= 1 - Self.endingPromptWindow else {
            beginFailedEnding()
            return
        }

        switch endingSequencePhase {
        case .preparePrompt:
            playEndingPreparationSequence()
        case .jumpPrompt:
            beginSuccessfulEnding()
        default:
            break
        }
    }

    private func playEndingPreparationSequence() {
        guard endingSequencePhase == .preparePrompt,
              let preparation = endingPreparationNode else { return }
        endingSequencePhase = .preparing
        endingPromptStep = nil
        onEndingPromptChanged?(nil, 0)
        preparation.removeAllActions()
        let frames = GameSpriteSheet.endingPreparationFrames
        preparation.texture = frames[0]
        preparation.size = CGSize(width: 66, height: 132)
        preparation.run(.sequence([
            .animate(with: frames,
                     timePerFrame: 0.14,
                     resize: false,
                     restore: false),
            .run { [weak self, weak preparation] in
                preparation?.texture = frames[3]
                preparation?.size = CGSize(width: 66, height: 132)
                self?.showEndingPrompt(.jump, phase: .jumpPrompt)
            }
        ]), withKey: "endingPreparationAnimation")
    }

    private func beginSuccessfulEnding() {
        guard let endingSetpiece else { return }
        endingSequencePhase = .successFlight
        endingPromptStep = nil
        onEndingPromptChanged?(nil, 0)
        player.stopAnimations()
        player.isHidden = true
        endingPreparationNode?.removeAllActions()
        endingPreparationNode?.removeFromParent()
        endingPreparationNode = nil

        // Hide the combined artwork first, then add its separated replacements in the same frame.
        let scooter = SKSpriteNode(imageNamed: "EndingUnmannedScooter")
        scooter.name = "endingUnmannedScooter"
        scooter.size = CGSize(width: 48, height: 72)
        scooter.position = CGPoint(x: player.position.x - 5, y: player.position.y - 12)
        scooter.zPosition = 30
        addChild(scooter)

        let jumpFrames = GameSpriteSheet.endingJumpFrames
        let rider = SKSpriteNode(texture: jumpFrames[0])
        rider.name = "endingDivingRider"
        rider.size = CGSize(width: 72, height: 132)
        rider.position = CGPoint(x: player.position.x + 5, y: player.position.y + 3)
        rider.zPosition = 31
        addChild(rider)

        let doorTarget = endingSetpiece.convert(endingSetpiece.doorTarget, to: self)
        let impactPoint = endingSetpiece.convert(endingSetpiece.scooterImpactPoint, to: self)
        // Let the rider finish the doorway motion before the scooter reaches the wall.
        // Starting both motions together made the explosion visually read as a rider
        // crash even after the second timing prompt succeeded.
        let riderEntry = SKAction.group([
            .animate(with: jumpFrames,
                     timePerFrame: 0.13,
                     resize: false,
                     restore: false),
            .move(to: doorTarget, duration: 0.72),
            .scale(to: 0.78, duration: 0.72)
        ])
        riderEntry.timingMode = .easeInEaseOut
        rider.run(.sequence([
            riderEntry,
            .group([.scale(to: 0.18, duration: 0.14), .fadeOut(withDuration: 0.14)]),
            .removeFromParent()
        ]), withKey: "endingRiderEntry")

        // The scooter keeps moving while the rider dives inside. Its impact occurs
        // only after the doorway animation has removed the rider.
        let scooterRide = SKAction.move(to: impactPoint, duration: 1.15)
        scooterRide.timingMode = .easeIn
        scooter.run(.sequence([
            scooterRide,
            .run { [weak self, weak scooter] in
                scooter?.removeFromParent()
                guard let self else { return }
                self.playEndingExplosion(at: impactPoint,
                                         result: GameRules.deliveryResult(for: self.gameState))
            }
        ]))
    }

    private func beginFailedEnding() {
        guard let endingSetpiece else { return }
        endingSequencePhase = .failedCrash
        endingPromptStep = nil
        onEndingPromptChanged?(nil, 0)
        player.stopAnimations()
        endingPreparationNode?.removeAllActions()
        endingPreparationNode?.removeFromParent()
        endingPreparationNode = nil
        player.isHidden = false
        player.physicsBody = nil

        let impactPoint = endingSetpiece.convert(endingSetpiece.scooterImpactPoint, to: self)
        let crashPoint = CGPoint(x: player.position.x, y: impactPoint.y)
        let crash = SKAction.move(to: crashPoint, duration: 0.82)
        crash.timingMode = .easeIn
        player.run(.sequence([
            crash,
            .run { [weak self] in
                guard let self else { return }
                self.player.isHidden = true
                self.playEndingExplosion(at: crashPoint, result: .crashedAtDestination)
            }
        ]), withKey: "endingCrash")
    }

    private func playEndingExplosion(at position: CGPoint, result: GameEndReason) {
        guard endingSequencePhase != .exploding else { return }
        endingSequencePhase = .exploding
        let explosion = MolotovExplosionNode(position: position)
        explosion.zPosition = 32
        addChild(explosion)
        run(.playSoundFileNamed(GameConstants.molotovExplosionSoundName,
                                waitForCompletion: false))
        run(.sequence([
            .wait(forDuration: 0.76),
            .run { [weak self] in self?.finish(with: result) }
        ]), withKey: "endingExplosion")
    }

    private func publishState() {
        onStateChanged?(gameState)
    }

    private func updateEncounters(deltaTime: TimeInterval) {
        if !didSpawnThief, elapsedStageTime >= GameConstants.thiefSpawnTime {
            didSpawnThief = true
            let thiefOnLeft = Bool.random()
            let sideInset: CGFloat = 10
            let thiefX = thiefOnLeft
                ? size.width / 2 - routeWidth / 2 + sideInset
                : size.width / 2 + routeWidth / 2 - sideInset
            let entryStartX = thiefX - (thiefOnLeft ? CGFloat(1) : CGFloat(-1)) * 30
            let thief = EncounterNode(kind: .thief,
                                      position: CGPoint(x: thiefX,
                                                        y: size.height - GameConstants.topTouchExclusionHeight - 105),
                                      horizontalDirection: thiefOnLeft ? 1 : -1,
                                      entryStartX: entryStartX,
                                      entryDuration: GameConstants.sideHazardEntryDuration)
            encounterNodeLayer.addChild(thief)
            run(.playSoundFileNamed(GameConstants.dangerSoundName,
                                    waitForCompletion: false))
        }

        if !didSpawnPidgeot, elapsedStageTime >= GameConstants.pidgeotSpawnTime {
            didSpawnPidgeot = true
            let direction: CGFloat = Bool.random() ? 1 : -1
            let startX = direction > 0 ? -70 : size.width + 70
            let pidgeot = EncounterNode(kind: .pidgeot,
                                        position: CGPoint(x: startX,
                                                          y: size.height - GameConstants.topTouchExclusionHeight - 105),
                                        horizontalDirection: direction)
            encounterNodeLayer.addChild(pidgeot)
        }

        for encounter in encounterNodeLayer.children.compactMap({ $0 as? EncounterNode }) {
            encounter.update(deltaTime: deltaTime,
                             targetX: player.position.x,
                             targetY: player.position.y,
                             routeWidth: routeWidth,
                             sceneWidth: size.width)

            let releasedEffect = encounter.projectileToThrow(deltaTime: deltaTime)
            if encounter.didBeginThiefWarningThisFrame {
                run(.playSoundFileNamed(GameConstants.dangerSoundName,
                                        waitForCompletion: false),
                    withKey: "thiefThrowWarning")
            }

            if let effect = releasedEffect {
                let projectile: ProjectileNode
                if encounter.kind == .thief {
                    // Capture the player's location at release. The projectile's velocity
                    // is fixed after this point, so sidestepping remains effective.
                    let dx = player.position.x - encounter.position.x
                    let dy = player.position.y - encounter.position.y
                    let distanceToPlayer = max(1, hypot(dx, dy))
                    let direction = CGVector(dx: dx / distanceToPlayer,
                                             dy: dy / distanceToPlayer)
                    let muzzleOffset: CGFloat = 15
                    let startPosition = CGPoint(x: encounter.position.x + direction.dx * muzzleOffset,
                                                y: encounter.position.y + direction.dy * muzzleOffset)
                    let distanceFromMuzzle = hypot(player.position.x - startPosition.x,
                                                   player.position.y - startPosition.y)
                    let speed = effect == .burningDamage
                        ? GameConstants.thiefMolotovSpeed
                        : GameConstants.thiefKnifeSpeed
                    projectile = ProjectileNode(
                        effect: effect,
                        position: startPosition,
                        velocity: CGVector(dx: direction.dx * speed,
                                           dy: direction.dy * speed),
                        maximumDistance: distanceFromMuzzle + 52
                    )
                } else {
                    projectile = ProjectileNode(
                        effect: effect,
                        position: CGPoint(x: encounter.position.x,
                                          y: encounter.position.y - 55),
                        velocity: CGVector(dx: 0, dy: -GameConstants.projectileSpeed)
                    )
                }
                encounterNodeLayer.addChild(projectile)
            }

            if encounter.hasExpired || encounter.hasExitedSide(sceneWidth: size.width) {
                encounter.removeFromParent()
            }
        }

        for projectile in encounterNodeLayer.children.compactMap({ $0 as? ProjectileNode }) {
            let hasReachedTarget = projectile.updateMovement(deltaTime: deltaTime)
            let isOffscreen = projectile.position.x < -60 || projectile.position.x > size.width + 60 ||
                projectile.position.y < -60 || projectile.position.y > size.height + 60
            if hasReachedTarget || isOffscreen {
                projectile.removeFromParent()
            }
        }
    }

    private func updateMolotovProjectiles(deltaTime: TimeInterval) {
        for molotov in encounterNodeLayer.children.compactMap({ $0 as? MolotovProjectileNode }) {
            molotov.updateMovement(deltaTime: deltaTime)
            let isOffscreen = molotov.position.x < -100 ||
                molotov.position.x > size.width + 100 ||
                molotov.position.y < -100 ||
                molotov.position.y > size.height + 100
            if isOffscreen {
                molotov.removeFromParent()
            }
        }
    }

    private func updateWorldHazards(deltaTime: TimeInterval) {
        hazardSpawnTimer += deltaTime
        if hazardSpawnTimer >= GameConstants.hazardSpawnInterval {
            hazardSpawnTimer = 0

            let definitions: [HazardDefinition] = [.cat, .cow]
            let definition = definitions[hazardSpawnIndex % definitions.count]
            let spawnY = size.height - GameConstants.topTouchExclusionHeight + 90 - worldNode.position.y
            let hazardDirection: CGFloat = Bool.random() ? 1 : -1
            let spawnX: CGFloat
            let hazardY: CGFloat
            if definition.kind == .cow {
                let crossingDistance = routeWidth / 2 + definition.size.width / 2 - 8
                spawnX = size.width / 2 - hazardDirection * crossingDistance
                hazardY = spawnY
            } else {
                spawnX = size.width / 2 - hazardDirection * (routeWidth / 2 + 8)
                hazardY = spawnY
            }
            let position = CGPoint(x: spawnX, y: hazardY)
            worldNode.addChild(nodeFactory.makeHazard(definition: definition,
                                                      position: position,
                                                      horizontalDirection: hazardDirection))
            switch definition.kind {
            case .cat:
                break // Cat cues are synchronized to its visible warning and pounce.
            case .cow:
                run(.playSoundFileNamed(GameConstants.cowSpawnSoundName,
                                        waitForCompletion: false))
            }
            hazardSpawnIndex += 1
        }

        for hazard in worldNode.children.compactMap({ $0 as? HazardNode }) {
            if hazard.hasExitedSide(sceneWidth: size.width) {
                hazard.removeFromParent()
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let playerAndObstacle = GameConstants.playerPhysicsCategory | GameConstants.obstaclePhysicsCategory
        guard categories == playerAndObstacle else { return }

        handleObstacleContact(at: lastUpdateTime ?? 0)
        let hazard = contact.bodyA.node as? HazardNode ?? contact.bodyB.node as? HazardNode
        hazard?.removeFromParent()
    }
}
