//
//  BonusNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum BonusKind: Equatable {
    case foodSteal
    case fire
    case water

    var size: CGSize {
        CGSize(width: 58, height: 58)
    }

    var color: SKColor {
        switch self {
        case .foodSteal:
            return .systemGreen
        case .fire:
            return .systemOrange
        case .water:
            return .systemCyan
        }
    }

    var label: String {
        switch self {
        case .foodSteal:
            return ""
        case .fire:
            return "+ HEAT"
        case .water:
            return "WATER"
        }
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
        name = "bonus-\(kind)"

        if kind == .foodSteal {
            let sheet = SKTexture(imageNamed: "DeliverWhileHotPizzaStealEvent")
            let frames = (0..<4).map { index in
                SKTexture(rect: CGRect(x: CGFloat(index) / 4,
                                       y: 0,
                                       width: 1.0 / 4,
                                       height: 1),
                          in: sheet)
            }
            let sprite = SKSpriteNode(texture: frames[0])
            sprite.size = CGSize(width: 132, height: 104)
            sprite.zPosition = 5
            addChild(sprite)
            eventSprite = sprite
        } else {
            let visual = SKShapeNode(rectOf: size, cornerRadius: 14)
            visual.fillColor = kind.color.withAlphaComponent(0.9)
            visual.strokeColor = .white
            visual.lineWidth = 3
            addChild(visual)

            let labelNode = SKLabelNode(text: kind.label)
            labelNode.fontName = "AvenirNext-Bold"
            labelNode.fontSize = 11
            labelNode.fontColor = .white
            labelNode.verticalAlignmentMode = .center
            addChild(labelNode)
        }

        let pulse = SKAction.sequence([
            .scale(to: 1.08, duration: 0.45),
            .scale(to: 1.0, duration: 0.45)
        ])
        if kind != .foodSteal {
            run(.repeatForever(pulse), withKey: "bonusPulse")
        }
    }

    func collect() {
        guard !isCollected else { return }
        isCollected = true
        removeAction(forKey: "bonusPulse")

        guard let eventSprite else {
            removeFromParent()
            return
        }

        let sheet = SKTexture(imageNamed: "DeliverWhileHotPizzaStealEvent")
        let frames = (0..<4).map { index in
            SKTexture(rect: CGRect(x: CGFloat(index) / 4,
                                   y: 0,
                                   width: 1.0 / 4,
                                   height: 1),
                      in: sheet)
        }
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
