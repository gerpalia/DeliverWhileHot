//
//  MolotovNodes.swift
//  DeliverWhileHot
//

import SpriteKit

final class MolotovProjectileNode: SKNode {
    private let spriteNode: SKSpriteNode
    private let velocity: CGVector

    init(position: CGPoint, velocity: CGVector) {
        self.velocity = velocity
        self.spriteNode = SKSpriteNode(texture: SKTexture(imageNamed: "DeliverWhileHotMolotovProjectile"))
        super.init()

        name = "molotovProjectile"
        self.position = position
        spriteNode.size = CGSize(width: 72, height: 48)
        spriteNode.zRotation = atan2(velocity.dy, velocity.dx) - (.pi / 4)
        spriteNode.zPosition = 20
        addChild(spriteNode)
    }

    func updateMovement(deltaTime: TimeInterval) {
        position.x += velocity.dx * CGFloat(deltaTime)
        position.y += velocity.dy * CGFloat(deltaTime)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("MolotovProjectileNode does not support NSCoder initialization")
    }
}

final class MolotovExplosionNode: SKNode {
    private let spriteNode: SKSpriteNode

    init(position: CGPoint) {
        let sheet = SKTexture(imageNamed: "DeliverWhileHotMolotovExplosion")
        self.spriteNode = SKSpriteNode(texture: sheet)
        super.init()

        name = "molotovExplosion"
        self.position = position
        spriteNode.size = CGSize(width: 78, height: 156)
        spriteNode.zPosition = 18
        addChild(spriteNode)

        let frames = (0..<6).map { index in
            SKTexture(
                rect: CGRect(x: CGFloat(index) / 6.0,
                            y: 0,
                            width: 1.0 / 6.0,
                            height: 1),
                in: sheet
            )
        }
        spriteNode.texture = frames[0]
        let animation = SKAction.animate(with: frames,
                                         timePerFrame: 0.10,
                                         resize: false,
                                         restore: false)
        spriteNode.run(.sequence([
            animation,
            .removeFromParent()
        ]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("MolotovExplosionNode does not support NSCoder initialization")
    }
}
