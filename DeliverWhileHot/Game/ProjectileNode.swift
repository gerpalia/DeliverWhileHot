//
//  ProjectileNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum ProjectileEffect {
    case damageHealth
    case spoilFood
}

final class ProjectileNode: SKNode {
    private let visualNode: SKShapeNode
    let effect: ProjectileEffect
    private var velocity: CGVector
    private var remainingDistance: CGFloat?

    init(effect: ProjectileEffect,
         position: CGPoint,
         velocity: CGVector = CGVector(dx: 0, dy: 0),
         maximumDistance: CGFloat? = nil) {
        self.effect = effect
        self.velocity = velocity
        self.remainingDistance = maximumDistance
        self.visualNode = SKShapeNode(circleOfRadius: 10)
        super.init()
        name = "projectile"
        self.position = position
        switch effect {
        case .damageHealth:
            visualNode.fillColor = .systemOrange
        case .spoilFood:
            visualNode.fillColor = .brown
        }
        visualNode.strokeColor = .white
        visualNode.lineWidth = 2
        addChild(visualNode)
    }

    @discardableResult
    func updateMovement(deltaTime: TimeInterval) -> Bool {
        let distance = CGFloat(deltaTime)
        position.x += velocity.dx * distance
        position.y += velocity.dy * distance

        if let remainingDistance {
            self.remainingDistance = remainingDistance - max(abs(velocity.dx), abs(velocity.dy)) * distance
            return (self.remainingDistance ?? 0) <= 0
        }
        return false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("ProjectileNode does not support NSCoder initialization")
    }
}
