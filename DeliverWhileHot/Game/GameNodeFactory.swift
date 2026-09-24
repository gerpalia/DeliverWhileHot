//
//  GameNodeFactory.swift
//  DeliverWhileHot
//

import SpriteKit

struct GameNodeFactory {
    func makeRoad(width: CGFloat, height: CGFloat) -> SKShapeNode {
        let road = SKShapeNode(rectOf: CGSize(width: width, height: height))
        road.fillColor = GameConstants.roadColor
        road.strokeColor = .clear
        road.position = CGPoint(x: width / 2, y: height / 2)
        return road
    }

    func makeLaneMarkers(width: CGFloat, height: CGFloat) -> [SKShapeNode] {
        stride(from: 70, through: height - 70, by: 140).map { y in
            let dash = SKShapeNode(rectOf: CGSize(width: 8, height: 70), cornerRadius: 4)
            dash.fillColor = .white.withAlphaComponent(0.28)
            dash.strokeColor = .clear
            dash.position = CGPoint(x: width / 2, y: y)
            return dash
        }
    }

    func makeBoundaries(width: CGFloat, routeWidth: CGFloat, height: CGFloat) -> [SKShapeNode] {
        [width / 2 - routeWidth / 2, width / 2 + routeWidth / 2].map { x in
            let boundary = SKShapeNode(rectOf: CGSize(width: 10, height: height))
            boundary.fillColor = .yellow.withAlphaComponent(0.8)
            boundary.strokeColor = .clear
            boundary.position = CGPoint(x: x, y: height / 2)
            return boundary
        }
    }

    func makePlayer() -> SKShapeNode {
        let player = SKShapeNode(rectOf: GameConstants.playerSize,
                                 cornerRadius: GameConstants.playerCornerRadius)
        player.fillColor = GameConstants.playerColor
        player.strokeColor = .white
        player.lineWidth = 3

        let body = SKPhysicsBody(rectangleOf: GameConstants.playerSize)
        body.categoryBitMask = GameConstants.playerPhysicsCategory
        body.collisionBitMask = 0
        body.contactTestBitMask = GameConstants.obstaclePhysicsCategory
        body.affectedByGravity = false
        body.allowsRotation = false
        body.isDynamic = true
        player.physicsBody = body
        return player
    }

    func makeObstacles(width: CGFloat, routeWidth: CGFloat, height: CGFloat) -> [SKShapeNode] {
        let placements: [(CGFloat, CGFloat)] = [(0.28, -0.20), (0.48, 0.18), (0.68, -0.10)]
        return placements.map { heightFraction, horizontalOffset in
            let obstacle = SKShapeNode(circleOfRadius: GameConstants.obstacleRadius)
            obstacle.name = "obstacle"
            obstacle.fillColor = GameConstants.obstacleColor
            obstacle.strokeColor = .black
            obstacle.lineWidth = 4
            obstacle.position = CGPoint(x: width / 2 + routeWidth * horizontalOffset,
                                        y: height * heightFraction)

            let body = SKPhysicsBody(circleOfRadius: GameConstants.obstacleRadius)
            body.categoryBitMask = GameConstants.obstaclePhysicsCategory
            body.collisionBitMask = 0
            body.contactTestBitMask = GameConstants.playerPhysicsCategory
            body.affectedByGravity = false
            body.isDynamic = false
            obstacle.physicsBody = body
            return obstacle
        }
    }

    func makeDestination(width: CGFloat, routeWidth: CGFloat, height: CGFloat) -> SKShapeNode {
        let destination = SKShapeNode(rectOf: CGSize(width: routeWidth - 36,
                                                       height: GameConstants.destinationHeight),
                                      cornerRadius: 18)
        destination.name = "destination"
        destination.fillColor = GameConstants.destinationColor.withAlphaComponent(0.35)
        destination.strokeColor = GameConstants.destinationColor
        destination.lineWidth = 5
        destination.position = CGPoint(x: width / 2,
                                       y: height - GameConstants.destinationTopInset)

        let label = SKLabelNode(text: "DELIVERY")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        destination.addChild(label)
        return destination
    }
}
