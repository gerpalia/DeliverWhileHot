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

    func configure(for viewSize: CGSize) {
        guard !isConfigured, viewSize.width > 0, viewSize.height > 0 else { return }
        isConfigured = true

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
    }

    override func update(_ currentTime: TimeInterval) {
        guard isConfigured, !hasReachedDestination else { return }
        let deltaTime = min(currentTime - (lastUpdateTime ?? currentTime), 1.0 / 20.0)
        lastUpdateTime = currentTime

        worldNode.position.y -= GameConstants.automaticScrollSpeed * deltaTime
        if worldNode.position.y <= -routeHeight {
            worldNode.position.y += routeHeight
        }

        player.position.x += (targetX - player.position.x) * GameConstants.movementSmoothing

        let halfRoad = routeWidth / 2 - player.frame.width / 2 - 8
        player.position.x = min(max(player.position.x, size.width / 2 - halfRoad),
                                size.width / 2 + halfRoad)

        checkSceneInteractions(at: currentTime)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTarget(with: touches.first)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTarget(with: touches.first)
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
            hasReachedDestination = true
            worldNode.removeAllActions()
            player.removeAllActions()
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
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let playerAndObstacle = GameConstants.playerPhysicsCategory | GameConstants.obstaclePhysicsCategory
        guard categories == playerAndObstacle else { return }

        handleObstacleContact(at: lastUpdateTime ?? 0)
    }
}
