//
//  HealingEffectNode.swift
//  DeliverWhileHot
//

import SpriteKit

final class HealingEffectNode: SKSpriteNode {
    init() {
        let sheet = SKTexture(imageNamed: "DeliverWhileHotHealingEffect")
        let frames = (0..<4).map { index in
            SKTexture(rect: CGRect(x: CGFloat(index) / 4,
                                   y: 0,
                                   width: 1.0 / 4,
                                   height: 1),
                      in: sheet)
        }

        super.init(texture: frames.first, color: .clear, size: CGSize(width: 132, height: 132))
        name = "healingEffect"
        zPosition = 10

        run(.sequence([
            .animate(with: frames, timePerFrame: 0.10, resize: false, restore: false),
            .fadeOut(withDuration: 0.14),
            .removeFromParent()
        ]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("HealingEffectNode does not support NSCoder initialization")
    }
}
