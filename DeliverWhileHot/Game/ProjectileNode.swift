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

    init(effect: ProjectileEffect, position: CGPoint) {
        self.effect = effect
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("ProjectileNode does not support NSCoder initialization")
    }
}
