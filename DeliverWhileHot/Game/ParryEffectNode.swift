//
//  ParryEffectNode.swift
//  DeliverWhileHot
//

import SpriteKit

final class ParryEffectNode: SKSpriteNode {
    init(position: CGPoint) {
        let sheet = SKTexture(imageNamed: "DeliverWhileHotParryEffect")
        let frames = (0..<4).map { index in
            SKTexture(rect: CGRect(x: CGFloat(index) / 4,
                                   y: 0,
                                   width: 1.0 / 4,
                                   height: 1),
                      in: sheet)
        }

        super.init(texture: frames.first, color: .clear, size: CGSize(width: 150, height: 150))
        self.position = position
        name = "parryEffect"
        zPosition = 20

        run(.sequence([
            .animate(with: frames, timePerFrame: 0.07, resize: false, restore: false),
            .fadeOut(withDuration: 0.08),
            .removeFromParent()
        ]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("ParryEffectNode does not support NSCoder initialization")
    }
}
