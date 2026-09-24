//
//  GameScene.swift
//  DeliverWhileHot
//

import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private let nodeFactory = GameNodeFactory()
    private let worldNode = SKNode()
    private var player = SKShapeNode()
    private var targetX: CGFloat = 0
    private var routeWidth: CGFloat = 0
    private var routeHeight: CGFloat = 0
    private var lastUpdateTime: TimeInterval?
    private var lastCollisionTime: TimeInterval = -.infinity
    private var hasReachedDestination = false
    private var isConfigured = false
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

        nodeFactory.makeLaneMarkers(width: size.width, height: routeHeight).forEach(worldNode.addChild)
        nodeFactory.makeBoundaries(width: size.width, routeWidth: routeWidth, height: routeHeight).forEach(worldNode.addChild)
        nodeFactory.makeObstacles(width: size.width, routeWidth: routeWidth, height: routeHeight).forEach(worldNode.addChild)
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

        worldNode.position.y -= GameConstants.automaticScrollSpeed * deltaTime
        if worldNode.position.y <= -routeHeight {
            worldNode.position.y += routeHeight
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

        for obstacle in worldNode.children where obstacle.name == "obstacle" {
            let obstacleCenter = CGPoint(x: obstacle.position.x + worldNode.position.x,
                                         y: obstacle.position.y + worldNode.position.y)
            let horizontalDistance = abs(playerCenter.x - obstacleCenter.x)
            let verticalDistance = abs(playerCenter.y - obstacleCenter.y)
            let isOverlapping = horizontalDistance <= playerHalfWidth + GameConstants.obstacleRadius &&
                verticalDistance <= playerHalfHeight + GameConstants.obstacleRadius

            if isOverlapping {
                handleObstacleContact(at: time)
                break
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

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let playerAndObstacle = GameConstants.playerPhysicsCategory | GameConstants.obstaclePhysicsCategory
        guard categories == playerAndObstacle else { return }

        handleObstacleContact(at: lastUpdateTime ?? 0)
    }
}
