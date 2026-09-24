//
//  GameScene.swift
//  DeliverWhileHot
//

import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private let nodeFactory = GameNodeFactory()
    private let worldNode = SKNode()
    private let encounterNodeLayer = SKNode()
    private var player = SKShapeNode()
    private var targetX: CGFloat = 0
    private var routeWidth: CGFloat = 0
    private var routeHeight: CGFloat = 0
    private var lastUpdateTime: TimeInterval?
    private var lastCollisionTime: TimeInterval = -.infinity
    private var hasReachedDestination = false
    private var isConfigured = false
    private var elapsedStageTime: TimeInterval = 0
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

        routeHeight = max(viewSize.height * GameConstants.routeHeightMultiplier,
                          GameConstants.minimumRouteHeight)
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

        player = nodeFactory.makePlayer()
        player.position = CGPoint(x: size.width / 2, y: viewSize.height * 0.22)
        targetX = player.position.x
        addChild(player)
        publishState()
    }

    override func update(_ currentTime: TimeInterval) {
        guard isConfigured, !hasReachedDestination, case .playing = gameState.phase else { return }
        let deltaTime = min(currentTime - (lastUpdateTime ?? currentTime), 1.0 / 20.0)
        lastUpdateTime = currentTime

        GameRules.advanceTemperature(&gameState, by: deltaTime)
        if gameState.foodTemperature <= 0 {
            finish(with: .foodTooCold)
            return
        }

        elapsedStageTime += deltaTime
        updateWorldHazards(deltaTime: deltaTime)
        updatePatrolOfficer(deltaTime: deltaTime)
        updateEncounters(deltaTime: deltaTime)

        worldNode.position.y -= GameConstants.automaticScrollSpeed * deltaTime
        if worldNode.position.y <= -routeHeight {
            worldNode.position.y += routeHeight
        }

        for hazard in worldNode.children.compactMap({ $0 as? HazardNode }) {
            hazard.updateBehavior(deltaTime: deltaTime,
                                  routeWidth: routeWidth,
                                  sceneWidth: size.width)
        }

        player.position.x += (targetX - player.position.x) * GameConstants.movementSmoothing

        let halfRoad = routeWidth / 2 - player.frame.width / 2 - 8
        player.position.x = min(max(player.position.x, size.width / 2 - halfRoad),
                                size.width / 2 + halfRoad)

        checkSceneInteractions(at: currentTime)
        publishState()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, acceptsGameplayTouch(touch) else { return }
        updateTarget(with: touch)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, acceptsGameplayTouch(touch) else { return }
        updateTarget(with: touch)
    }

    private func acceptsGameplayTouch(_ touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        let isInTopExcludedArea = location.y >= size.height - GameConstants.topTouchExclusionHeight
        let isInBottomExcludedArea = location.y <= GameConstants.bottomTouchExclusionHeight
        return !isInTopExcludedArea && !isInBottomExcludedArea
    }

    private func updateTarget(with touch: UITouch?) {
        guard let touch else { return }
        targetX = touch.location(in: self).x
    }

    private func checkSceneInteractions(at time: TimeInterval) {
        let playerCenter = player.position
        let playerHalfWidth = player.frame.width / 2
        let playerHalfHeight = player.frame.height / 2

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
                handleObstacleContact(at: time)
                break
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
                    handleObstacleContact(at: time)
                case .spoilFood:
                    handlePidgeotMess(at: time)
                }
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

    private func handleObstacleContact(at time: TimeInterval) {
        guard time - lastCollisionTime >= GameConstants.collisionCooldown else { return }
        lastCollisionTime = time

        player.removeAction(forKey: "collisionFeedback")
        let feedback = SKAction.sequence([
            .run { [weak self] in self?.player.fillColor = .red },
            .wait(forDuration: GameConstants.collisionFeedbackDuration),
            .run { [weak self] in self?.player.fillColor = GameConstants.playerColor }
        ])
        player.run(feedback, withKey: "collisionFeedback")
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

    func consumeFood() {
        guard case .playing = gameState.phase else { return }
        if GameRules.consumeFood(&gameState) {
            publishState()
        }
    }

    private func finish(with reason: GameEndReason) {
        guard case .playing = gameState.phase else { return }
        gameState.phase = .ended(reason)
        hasReachedDestination = true
        worldNode.removeAllActions()
        player.removeAllActions()
        publishState()
        onFinished?(reason)
    }

    private func publishState() {
        onStateChanged?(gameState)
    }

    private func updateEncounters(deltaTime: TimeInterval) {
        if !didSpawnThief, elapsedStageTime >= GameConstants.thiefSpawnTime {
            didSpawnThief = true
            let thief = EncounterNode(kind: .thief,
                                      position: CGPoint(x: size.width / 2 + routeWidth * 0.24,
                                                        y: size.height - GameConstants.topTouchExclusionHeight - 50))
            encounterNodeLayer.addChild(thief)
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
                let projectile = ProjectileNode(effect: effect,
                                                position: CGPoint(x: encounter.position.x,
                                                                  y: encounter.position.y - 55))
                encounterNodeLayer.addChild(projectile)
            }

            if encounter.hasExpired {
                encounter.removeFromParent()
            }
        }

        for projectile in encounterNodeLayer.children.compactMap({ $0 as? ProjectileNode }) {
            projectile.position.y -= GameConstants.projectileSpeed * CGFloat(deltaTime)
            if projectile.position.y < -40 {
                projectile.removeFromParent()
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
