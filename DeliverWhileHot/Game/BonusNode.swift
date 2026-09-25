//
//  BonusNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum BonusKind {
    case food
    case fire

    var size: CGSize {
        CGSize(width: 58, height: 58)
    }

    var color: SKColor {
        switch self {
        case .food:
            return .systemGreen
        case .fire:
            return .systemOrange
        }
    }

    var label: String {
        switch self {
        case .food:
            return "+ FOOD"
        case .fire:
            return "+ HEAT"
        }
    }
}

final class BonusNode: SKNode {
    let kind: BonusKind
    let size: CGSize

    init(kind: BonusKind, position: CGPoint) {
        self.kind = kind
        self.size = kind.size
        super.init()
        self.position = position
        name = "bonus-\(kind)"

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

        let pulse = SKAction.sequence([
            .scale(to: 1.08, duration: 0.45),
            .scale(to: 1.0, duration: 0.45)
        ])
        run(.repeatForever(pulse), withKey: "bonusPulse")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
