//
//  ProjectileNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum ProjectileEffect {
    case knifeDamage
    case burningDamage
    case spoilFood
}

final class ProjectileNode: SKNode {
    private let visualNode: SKNode
    let effect: ProjectileEffect
    private var velocity: CGVector
    private var remainingDistance: CGFloat?
    private(set) var isReflected = false

    var hitRadius: CGFloat {
        switch effect {
        case .knifeDamage: 8
        case .burningDamage: 13
        case .spoilFood: 10
        }
    }

    init(effect: ProjectileEffect,
         position: CGPoint,
         velocity: CGVector = CGVector(dx: 0, dy: 0),
         maximumDistance: CGFloat? = nil) {
        self.effect = effect
        self.velocity = velocity
        self.remainingDistance = maximumDistance
        switch effect {
        case .knifeDamage:
            let knife = SKNode()
            let bladePath = CGMutablePath()
            bladePath.move(to: CGPoint(x: -3, y: -3))
            bladePath.addLine(to: CGPoint(x: 14, y: 0))
            bladePath.addLine(to: CGPoint(x: -3, y: 3))
            bladePath.closeSubpath()
            let blade = SKShapeNode(path: bladePath)
            blade.fillColor = SKColor(red: 0.82, green: 0.86, blue: 0.88, alpha: 1)
            blade.strokeColor = SKColor(red: 0.12, green: 0.13, blue: 0.15, alpha: 1)
            blade.lineWidth = 1
            let handle = SKShapeNode(rectOf: CGSize(width: 9, height: 5), cornerRadius: 1.5)
            handle.position = CGPoint(x: -7, y: 0)
            handle.fillColor = SKColor(red: 0.38, green: 0.16, blue: 0.10, alpha: 1)
            handle.strokeColor = SKColor(red: 0.10, green: 0.08, blue: 0.07, alpha: 1)
            handle.lineWidth = 1
            knife.addChild(blade)
            knife.addChild(handle)
            self.visualNode = knife
        case .burningDamage:
            let bottle = SKSpriteNode(imageNamed: "DeliverWhileHotMolotovProjectile")
            bottle.size = CGSize(width: 34, height: 23)
            self.visualNode = bottle
        case .spoilFood:
            let mess = SKShapeNode(circleOfRadius: 10)
            mess.fillColor = .brown
            mess.strokeColor = .white
            mess.lineWidth = 2
            self.visualNode = mess
        }
        super.init()
        name = "projectile"
        self.position = position
        if effect != .spoilFood {
            visualNode.zRotation = atan2(velocity.dy, velocity.dx) -
                (effect == .burningDamage ? .pi / 4 : 0)
        }
        addChild(visualNode)
    }

    @discardableResult
    func updateMovement(deltaTime: TimeInterval) -> Bool {
        let distance = CGFloat(deltaTime)
        position.x += velocity.dx * distance
        position.y += velocity.dy * distance

        if let remainingDistance {
            self.remainingDistance = remainingDistance - hypot(velocity.dx, velocity.dy) * distance
            return (self.remainingDistance ?? 0) <= 0
        }
        return false
    }

    func reflect() {
        guard effect != .spoilFood else { return }
        velocity = CGVector(dx: -velocity.dx, dy: -velocity.dy)
        remainingDistance = nil
        isReflected = true
        if let sprite = visualNode as? SKSpriteNode {
            sprite.color = .systemYellow
            sprite.colorBlendFactor = 0.7
        }
        for child in visualNode.children.compactMap({ $0 as? SKShapeNode }) {
            child.fillColor = .systemYellow
        }
        visualNode.removeAction(forKey: "reflectedPulse")
        visualNode.run(.repeatForever(.sequence([
            .scale(to: 1.25, duration: 0.08),
            .scale(to: 1.0, duration: 0.08)
        ])), withKey: "reflectedPulse")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("ProjectileNode does not support NSCoder initialization")
    }
}
