//
//  HazardDefinition.swift
//  DeliverWhileHot
//

import SpriteKit

enum HazardKind {
    case cat
    case cow
}

enum HazardMovement {
    case stationary
    case drifting(amplitude: CGFloat, frequency: CGFloat)
    case crossing(speed: CGFloat)
    case pounce(upwardDistance: CGFloat, waitDuration: TimeInterval, duration: TimeInterval)
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
        movement: .pounce(upwardDistance: 150, waitDuration: 0.85, duration: 0.66),
        color: .systemYellow
    )

    static let cow = HazardDefinition(
        kind: .cow,
        displayName: "COW",
        size: CGSize(width: 110, height: 82),
        collisionShape: .rectangle(size: CGSize(width: 110, height: 82)),
        damage: 1,
        movement: .crossing(speed: 100),
        color: .systemBrown
    )

}
