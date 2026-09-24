//
//  HazardDefinition.swift
//  DeliverWhileHot
//

import SpriteKit

enum HazardKind {
    case cat
    case cow
    case thief
}

enum HazardMovement {
    case stationary
    case drifting(amplitude: CGFloat, frequency: CGFloat)
}

enum HazardCollisionShape {
    case rectangle(size: CGSize)
    case circle(radius: CGFloat)
}

struct HazardDefinition {
    let kind: HazardKind
    let displayName: String
    let size: CGSize
    let collisionShape: HazardCollisionShape
    let damage: Int
    let movement: HazardMovement
    let color: SKColor
}

extension HazardDefinition {
    static let cat = HazardDefinition(
        kind: .cat,
        displayName: "CAT",
        size: CGSize(width: 38, height: 38),
        collisionShape: .circle(radius: 19),
        damage: 1,
        movement: .drifting(amplitude: 45, frequency: 2.4),
        color: .systemYellow
    )

    static let cow = HazardDefinition(
        kind: .cow,
        displayName: "COW",
        size: CGSize(width: 110, height: 82),
        collisionShape: .rectangle(size: CGSize(width: 110, height: 82)),
        damage: 1,
        movement: .drifting(amplitude: 55, frequency: 0.8),
        color: .systemBrown
    )

    static let thief = HazardDefinition(
        kind: .thief,
        displayName: "THIEF",
        size: CGSize(width: 58, height: 72),
        collisionShape: .rectangle(size: CGSize(width: 58, height: 72)),
        damage: 1,
        movement: .stationary,
        color: .systemPurple
    )
}
