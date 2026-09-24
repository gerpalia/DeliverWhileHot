//
//  HazardNode.swift
//  DeliverWhileHot
//

import SpriteKit

final class HazardNode: SKNode {
    let definition: HazardDefinition
    private let visualNode: SKShapeNode
    private let baseX: CGFloat
    private var behaviorTime: CGFloat = 0

    init(definition: HazardDefinition, position: CGPoint) {
        self.definition = definition
        self.baseX = position.x
        self.visualNode = HazardNode.makeVisualNode(for: definition)
        super.init()

        name = "hazard"
        self.position = position
        addChild(visualNode)

        let physicsBody: SKPhysicsBody
        switch definition.collisionShape {
        case let .rectangle(size):
            physicsBody = SKPhysicsBody(rectangleOf: size)
        case let .circle(radius):
            physicsBody = SKPhysicsBody(circleOfRadius: radius)
        }

        physicsBody.categoryBitMask = GameConstants.obstaclePhysicsCategory
        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask = GameConstants.playerPhysicsCategory
        physicsBody.affectedByGravity = false
        physicsBody.isDynamic = false
        self.physicsBody = physicsBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("HazardNode does not support NSCoder initialization")
    }

    func updateBehavior(deltaTime: TimeInterval, routeWidth: CGFloat, sceneWidth: CGFloat) {
        guard case let .drifting(amplitude, frequency) = definition.movement else { return }
        behaviorTime += CGFloat(deltaTime)
        let offset = sin(behaviorTime * frequency) * amplitude
        let halfRoute = routeWidth / 2 - definition.size.width / 2 - 8
        let minimumX = sceneWidth / 2 - halfRoute
        let maximumX = sceneWidth / 2 + halfRoute
        position.x = min(max(baseX + offset, minimumX), maximumX)
    }

    private static func makeVisualNode(for definition: HazardDefinition) -> SKShapeNode {
        let node: SKShapeNode
        switch definition.collisionShape {
        case let .rectangle(size):
            node = SKShapeNode(rectOf: size, cornerRadius: 12)
        case let .circle(radius):
            node = SKShapeNode(circleOfRadius: radius)
        }

        node.fillColor = definition.color
        node.strokeColor = .white
        node.lineWidth = 3

        let label = SKLabelNode(text: definition.displayName)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 10
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        node.addChild(label)
        return node
    }
}
