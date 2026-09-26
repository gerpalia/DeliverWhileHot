//
//  GameScene.swift
//  DeliverWhileHot
//

import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private let nodeFactory = GameNodeFactory()
    private let worldNode = SKNode()
    private let encounterNodeLayer = SKNode()
    private var player = PlayerNode()
    private var horizontalInput: CGFloat = 0
    private var verticalInput: CGFloat = 0
    private var lastMovementDirection = CGVector(dx: 0, dy: 1)
    private var routeWidth: CGFloat = 0
    private var routeHeight: CGFloat = 0
    private var lastUpdateTime: TimeInterval?
    private var lastCollisionTime: TimeInterval = -.infinity
    private var hasReachedDestination = false
    private var isConfigured = false
    private var elapsedStageTime: TimeInterval = 0
    private var freezeRemaining: TimeInterval = 0
    private var didSpawnOfficer = false
    private var didSpawnThief = false
    private var didSpawnPidgeot = false
    private var patrolOfficer: EncounterNode?
    private var hazardSpawnTimer: TimeInterval = 0
    private var hazardSpawnIndex = 0
    private(set) var gameState = GameState()
    private var onStateChanged: ((GameState) -> Void)?
    private var onFinished: ((GameEndReason) -> Void)?

    func configure(for viewSize: CGSize,
                   onStateChanged: ((GameState) -> Void)? = nil,
                   onFinished: ((GameEndReason) -> Void)? = nil) {
        guard !isConfigured, viewSize.width > 0, viewSize.height > 0 else { return }
        isConfigured = true
        self.onStateChanged = onStateChanged
        self.onFinished = onFinished

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
        addChild(nodeFactory.makeRoad(width: size.width, height: routeHeight))
        addChild(worldNode)
        addChild(encounterNodeLayer)

        nodeFactory.makeLaneMarkers(width: size.width, height: routeHeight).forEach(worldNode.addChild)
        nodeFactory.makeBoundaries(width: size.width, routeWidth: routeWidth, height: routeHeight).forEach(worldNode.addChild)
        worldNode.addChild(nodeFactory.makeDestination(width: size.width, routeWidth: routeWidth, height: routeHeight))
        worldNode.addChild(nodeFactory.makeBonus(
            kind: .food,
            position: CGPoint(x: size.width / 2 - routeWidth * 0.18,
                              y: routeHeight * 0.36)
        ))
        worldNode.addChild(nodeFactory.makeBonus(
            kind: .fire,
            position: CGPoint(x: size.width / 2 + routeWidth * 0.18,
                              y: routeHeight * 0.58)
        ))
        worldNode.addChild(nodeFactory.makeBonus(
            kind: .water,
            position: CGPoint(x: size.width / 2 - routeWidth * 0.18,
                              y: routeHeight * 0.76)
        ))

        player = nodeFactory.makePlayer()
        player.position = CGPoint(x: size.width / 2, y: viewSize.height * 0.22)
        addChild(player)
        publishState()
    }

    override func update(_ currentTime: TimeInterval) {
        guard isConfigured, !hasReachedDestination, case .playing = gameState.phase else { return }
        let deltaTime = min(currentTime - (lastUpdateTime ?? currentTime), 1.0 / 20.0)
        lastUpdateTime = currentTime

        if freezeRemaining > 0 {
            freezeRemaining = max(0, freezeRemaining - deltaTime)
            if freezeRemaining == 0 {
                endFreeze()
            }
            return
        }

        GameRules.advanceTemperature(&gameState, by: deltaTime)
        if gameState.foodTemperature <= 0 {
            finish(with: .foodTooCold)
            return
        }

        elapsedStageTime += deltaTime
        updateWorldHazards(deltaTime: deltaTime)
        updatePatrolOfficer(deltaTime: deltaTime)
        updateEncounters(deltaTime: deltaTime)
        updateMolotovProjectiles(deltaTime: deltaTime)

        worldNode.position.y -= GameConstants.automaticScrollSpeed * deltaTime
        if worldNode.position.y <= -routeHeight {
            finish(with: GameRules.deliveryResult(for: gameState))
            return
        }

        for hazard in worldNode.children.compactMap({ $0 as? HazardNode }) {
            hazard.updateBehavior(deltaTime: deltaTime,
                                  routeWidth: routeWidth,
                                  sceneWidth: size.width)
        }

        let movementMultiplier: CGFloat = player.isThrowing ? 0 : (player.isEating ? 0.45 : 1.0)
        player.setMovement(horizontal: horizontalInput, vertical: verticalInput)
        player.position.x += horizontalInput * GameConstants.playerMovementSpeed * movementMultiplier * CGFloat(deltaTime)
        player.position.y += verticalInput * GameConstants.playerVerticalMovementSpeed * movementMultiplier * CGFloat(deltaTime)

        let halfRoad = routeWidth / 2 - GameConstants.playerSize.width / 2 - 8
        player.position.x = min(max(player.position.x, size.width / 2 - halfRoad),
                                size.width / 2 + halfRoad)

        let minimumPlayerY = GameConstants.bottomTouchExclusionHeight + GameConstants.playerSize.height / 2 + 12
        let maximumPlayerY = size.height - GameConstants.topTouchExclusionHeight - GameConstants.playerSize.height / 2 - 12
        player.position.y = min(max(player.position.y, minimumPlayerY), maximumPlayerY)
        keepPlayerAwayFromJoystick()

        checkSceneInteractions(at: currentTime)
        publishState()
    }

    func movePlayer(direction: CGFloat) {
        guard case .playing = gameState.phase else { return }
        horizontalInput = direction
    }

    func setPlayerInput(horizontal: CGFloat, vertical: CGFloat) {
        guard case .playing = gameState.phase else { return }
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
        guard case .playing = gameState.phase else { return }
        verticalInput = direction
    }

    func stopPlayerVerticalMovement() {
        verticalInput = 0
    }

    func throwMolotov() {
        guard case .playing = gameState.phase,
              !player.isEating,
              !player.isThrowing else { return }

        let direction = lastMovementDirection
        _ = player.startThrowing { [weak self] in
            guard let self else { return }
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
        }
    }

    var canThrowMolotov: Bool {
        guard case .playing = gameState.phase else { return false }
        return !player.isEating && !player.isThrowing
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

        if let officer = patrolOfficer {
            let officerCenter = CGPoint(x: officer.position.x + worldNode.position.x,
                                        y: officer.position.y + worldNode.position.y)
            let horizontalDistance = abs(playerCenter.x - officerCenter.x)
            let verticalDistance = abs(playerCenter.y - officerCenter.y)
            let isOverlapping = horizontalDistance <= playerHalfWidth + 31 &&
                verticalDistance <= playerHalfHeight + 38

            if isOverlapping {
                handleOfficerInteraction(at: time)
            }
        }

        for encounter in encounterNodeLayer.children.compactMap({ $0 as? EncounterNode }) {
            let encounterCenter = encounter.position
            let horizontalDistance = abs(playerCenter.x - encounterCenter.x)
            let verticalDistance = abs(playerCenter.y - encounterCenter.y)
            let isOverlapping = horizontalDistance <= playerHalfWidth + 32 &&
                verticalDistance <= playerHalfHeight + 40

            if isOverlapping {
                switch encounter.kind {
                case .patrolOfficer:
                    handleOfficerInteraction(at: time)
                case .thief, .pidgeot:
                    handleObstacleContact(at: time)
                }
            }
        }

        for projectile in encounterNodeLayer.children.compactMap({ $0 as? ProjectileNode }) {
            let horizontalDistance = abs(playerCenter.x - projectile.position.x)
            let verticalDistance = abs(playerCenter.y - projectile.position.y)
            if horizontalDistance <= playerHalfWidth + 10 &&
                verticalDistance <= playerHalfHeight + 10 {
                projectile.removeFromParent()
                switch projectile.effect {
                case .damageHealth:
                    playMolotovImpactSound()
                    handleObstacleContact(at: time, startsBurning: true)
                case .spoilFood:
                    handlePidgeotMess(at: time)
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

            let leftWall = size.width / 2 - routeWidth / 2
            let rightWall = size.width / 2 + routeWidth / 2
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
            finish(with: GameRules.deliveryResult(for: gameState))
        }
    }

    private func keepPlayerAwayFromJoystick() {
        let visualHalfWidth = player.frame.width / 2
        let visualHalfHeight = player.frame.height / 2
        let isNearJoystick = player.position.x - visualHalfWidth < GameConstants.joystickSafeZoneRightEdge &&
            player.position.y - visualHalfHeight < GameConstants.joystickSafeZoneTopEdge

        guard isNearJoystick else { return }

        let safeX = GameConstants.joystickSafeZoneRightEdge + visualHalfWidth + 12
        let halfRoad = routeWidth / 2 - GameConstants.playerSize.width / 2 - 8
        player.position.x = min(safeX, size.width / 2 + halfRoad)
    }

    private func handleObstacleContact(at time: TimeInterval,
                                      startsBurning: Bool = false,
                                      hazardKind: HazardKind? = nil) {
        guard time - lastCollisionTime >= GameConstants.hitInvincibilityDuration else { return }
        lastCollisionTime = time

        if startsBurning {
            player.setBurning(true)
        }
        if let hazardKind, hazardKind == .cat {
            run(.playSoundFileNamed(GameConstants.catAttackSoundName,
                                    waitForCompletion: false))
        }
        player.playHitAnimation()
        if let hitSoundName = GameConstants.hitSoundNames.randomElement() {
            run(.playSoundFileNamed(hitSoundName, waitForCompletion: false),
                withKey: "hitSound")
        }
        beginFreeze(for: GameConstants.hitStopDuration)
        GameRules.applyObstacleDamage(&gameState)
        if gameState.health <= 0 {
            finish(with: .healthDepleted)
        }
        publishState()
    }

    private func handleOfficerInteraction(at time: TimeInterval) {
        guard time - lastCollisionTime >= GameConstants.collisionCooldown else { return }
        lastCollisionTime = time

        if GameRules.payOfficerBribe(&gameState) {
            publishState()
        }
    }

    private func handlePidgeotMess(at time: TimeInterval) {
        guard time - lastCollisionTime >= GameConstants.collisionCooldown else { return }
        lastCollisionTime = time
        GameRules.applyPidgeotMess(&gameState)
        publishState()
    }

    private func handleBonusCollection(_ bonus: BonusNode) {
        guard case .playing = gameState.phase else { return }
        bonus.removeFromParent()
        beginFreeze(for: GameConstants.bonusStopDuration)
        run(.playSoundFileNamed(GameConstants.bonusPickupSoundName,
                                waitForCompletion: false))

        switch bonus.kind {
        case .food:
            GameRules.applyFoodBonus(&gameState)
        case .fire:
            GameRules.applyFireBonus(&gameState)
            playBuffSound()
            if gameState.health <= 0 {
                finish(with: .healthDepleted)
                return
            }
        case .water:
            player.setBurning(false)
            playBuffSound()
        }

        publishState()
    }

    func consumeFood() {
        guard case .playing = gameState.phase else { return }
        guard GameRules.consumeFood(&gameState) else { return }
        run(.playSoundFileNamed(GameConstants.healthRecoverySoundName,
                                waitForCompletion: false),
            withKey: "healthRecoverySound")
        player.playHealthRecoveryAnimation()
        if player.startEating() {
            publishState()
        }
    }

    private func playBuffSound() {
        run(.playSoundFileNamed(GameConstants.buffShineSoundName,
                                waitForCompletion: false))
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
        gameState.phase = .ended(reason)
        hasReachedDestination = true
        horizontalInput = 0
        verticalInput = 0
        worldNode.removeAllActions()
        player.stopAnimations()
        publishState()
        onFinished?(reason)
    }

    private func publishState() {
        onStateChanged?(gameState)
    }

    private func updateEncounters(deltaTime: TimeInterval) {
        if !didSpawnThief, elapsedStageTime >= GameConstants.thiefSpawnTime {
            didSpawnThief = true
            let thiefOnLeft = Bool.random()
            let thiefHalfWidth: CGFloat = 29
            let sideInset: CGFloat = 42
            let thiefX = thiefOnLeft
                ? size.width / 2 - routeWidth / 2 + thiefHalfWidth + sideInset
                : size.width / 2 + routeWidth / 2 - thiefHalfWidth - sideInset
            let entryStartX = thiefOnLeft ? -thiefHalfWidth - 24 : size.width + thiefHalfWidth + 24
            let thief = EncounterNode(kind: .thief,
                                      position: CGPoint(x: thiefX,
                                                        y: size.height - GameConstants.topTouchExclusionHeight - 50),
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
                                                          y: size.height - GameConstants.topTouchExclusionHeight - 50),
                                        horizontalDirection: direction)
            encounterNodeLayer.addChild(pidgeot)
        }

        for encounter in encounterNodeLayer.children.compactMap({ $0 as? EncounterNode }) {
            encounter.update(deltaTime: deltaTime,
                             targetX: player.position.x,
                             targetY: player.position.y,
                             routeWidth: routeWidth,
                             sceneWidth: size.width)

            if encounter.shouldThrowProjectile(deltaTime: deltaTime),
               let effect = encounter.projectileEffect {
                let projectile: ProjectileNode
                if encounter.kind == .thief {
                    let direction: CGFloat = encounter.position.x < size.width / 2 ? 1 : -1
                    let projectedTargetX = min(max(player.position.x + direction * 60,
                                                   size.width / 2 - routeWidth / 2),
                                               size.width / 2 + routeWidth / 2)
                    let startX = encounter.position.x + direction * 38
                    projectile = ProjectileNode(
                        effect: effect,
                        position: CGPoint(x: startX, y: encounter.position.y),
                        velocity: CGVector(dx: direction * 320, dy: 0),
                        maximumDistance: abs(projectedTargetX - startX) + 60
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

            if encounter.hasExpired {
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

    private func updatePatrolOfficer(deltaTime: TimeInterval) {
        if !didSpawnOfficer, elapsedStageTime >= GameConstants.officerSpawnTime {
            didSpawnOfficer = true
            let officerHalfWidth: CGFloat = 31
            let minimumX = size.width / 2 - routeWidth / 2 + officerHalfWidth
            let maximumX = size.width / 2 + routeWidth / 2 - officerHalfWidth
            let randomX = CGFloat.random(in: minimumX...maximumX)
            let spawnY = size.height - GameConstants.topTouchExclusionHeight + 90 - worldNode.position.y
            let officer = EncounterNode(kind: .patrolOfficer,
                                        position: CGPoint(x: randomX, y: spawnY))
            patrolOfficer = officer
            worldNode.addChild(officer)
        }

        guard let officer = patrolOfficer else { return }
        officer.update(deltaTime: deltaTime,
                       targetX: player.position.x,
                       targetY: player.position.y,
                       routeWidth: routeWidth,
                       sceneWidth: size.width)
        if officer.hasExpired {
            officer.removeFromParent()
            patrolOfficer = nil
        }
    }

    private func updateWorldHazards(deltaTime: TimeInterval) {
        hazardSpawnTimer += deltaTime
        if hazardSpawnTimer >= GameConstants.hazardSpawnInterval {
            hazardSpawnTimer = 0

            let definitions: [HazardDefinition] = [.cat, .cow, .thief]
            let definition = definitions[hazardSpawnIndex % definitions.count]
            let offsets: [CGFloat] = [-0.24, 0.10, 0.22, -0.08, 0.16, -0.18]
            let offset = offsets[hazardSpawnIndex % offsets.count]
            let spawnY = size.height - GameConstants.topTouchExclusionHeight + 90 - worldNode.position.y
            let position = CGPoint(x: size.width / 2 + routeWidth * offset, y: spawnY)
            worldNode.addChild(nodeFactory.makeHazard(definition: definition, position: position))
            switch definition.kind {
            case .cat:
                run(.playSoundFileNamed(GameConstants.catSpawnSoundName,
                                        waitForCompletion: false))
            case .cow:
                run(.playSoundFileNamed(GameConstants.cowSpawnSoundName,
                                        waitForCompletion: false))
            case .thief:
                break
            }
            hazardSpawnIndex += 1
        }

        for hazard in worldNode.children.compactMap({ $0 as? HazardNode }) {
            let screenY = hazard.position.y + worldNode.position.y
            if screenY < -120 {
                hazard.removeFromParent()
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let playerAndObstacle = GameConstants.playerPhysicsCategory | GameConstants.obstaclePhysicsCategory
        guard categories == playerAndObstacle else { return }

        handleObstacleContact(at: lastUpdateTime ?? 0)
    }
}
