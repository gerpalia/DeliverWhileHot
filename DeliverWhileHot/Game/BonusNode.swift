//
//  BonusNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum BonusKind: Equatable {
    case foodSteal

    var size: CGSize {
        CGSize(width: 58, height: 58)
    }
}

final class BonusNode: SKNode {
    let kind: BonusKind
    let size: CGSize
    private(set) var isCollected = false
    private var eventSprite: SKSpriteNode?

    init(kind: BonusKind, position: CGPoint) {
        self.kind = kind
        self.size = kind.size
        super.init()
        self.position = position
        zPosition = 5
        name = "bonus-\(kind)"

        let sheet = SKTexture(imageNamed: "DeliverWhileHotPizzaStealEvent")
        let frames = (0..<4).map { index in
            SKTexture(rect: CGRect(x: CGFloat(index) / 4,
                                   y: 0,
                                   width: 1.0 / 4,
                                   height: 1),
                      in: sheet)
        }
        let glow = SKShapeNode(ellipseOf: CGSize(width: 112, height: 126))
        glow.position = CGPoint(x: 28, y: 0)
        glow.fillColor = SKColor(red: 1, green: 0.52, blue: 0.16, alpha: 0.18)
        glow.strokeColor = .clear
        glow.glowWidth = 18
        glow.zPosition = 0
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.58, duration: 0.7),
            .fadeAlpha(to: 0.88, duration: 0.7)
        ])), withKey: "deliveryGlow")
        addChild(glow)

        let props = SKTexture(imageNamed: "DeliverWhileHotNeighborhoodProps")
        let doorway = SKTexture(rect: CGRect(x: 0.39, y: 0.53,
                                             width: 0.34, height: 0.47),
                                in: props)
        let doorwaySprite = SKSpriteNode(texture: doorway)
        doorwaySprite.size = CGSize(width: 58, height: 88)
        doorwaySprite.position = CGPoint(x: 34, y: 0)
        doorwaySprite.zPosition = 1
        addChild(doorwaySprite)

        let sprite = SKSpriteNode(texture: frames[0])
        sprite.size = CGSize(width: 84, height: 112)
        sprite.position = CGPoint(x: 32, y: -4)
        sprite.zPosition = 5
        addChild(sprite)
        eventSprite = sprite
        sprite.run(.repeatForever(.animate(with: frames,
                                            timePerFrame: 0.32,
                                            resize: false,
                                            restore: false)),
                   withKey: "deliveryLoop")
        sprite.run(.repeatForever(.sequence([
            .scale(to: 1.035, duration: 0.64),
            .scale(to: 1.0, duration: 0.64)
        ])), withKey: "deliveryPulse")
    }

    func collect() {
        guard !isCollected else { return }
        isCollected = true
        guard let eventSprite else { removeFromParent(); return }

        let sheet = SKTexture(imageNamed: "DeliverWhileHotPizzaStealEvent")
        let frames = (0..<4).map { index in
            SKTexture(rect: CGRect(x: CGFloat(index) / 4,
                                   y: 0,
                                   width: 1.0 / 4,
                                   height: 1),
                      in: sheet)
        }
        eventSprite.removeAction(forKey: "deliveryLoop")
        eventSprite.run(.sequence([
            .animate(with: frames, timePerFrame: 0.12, resize: false, restore: false),
            .fadeOut(withDuration: 0.14),
            .removeFromParent()
        ])) { [weak self] in
            self?.removeFromParent()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
