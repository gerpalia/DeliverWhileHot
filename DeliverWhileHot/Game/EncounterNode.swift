//
//  EncounterNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum EncounterKind {
    case patrolOfficer
    case thief
    case pidgeot
}

final class EncounterNode: SKNode {
    let kind: EncounterKind
    private let visualNode: SKShapeNode
    private let fixedX: CGFloat
    private let horizontalDirection: CGFloat
    private var elapsedTime: TimeInterval = 0
    private var projectileTimer: TimeInterval = 0
    private(set) var projectilesThrown = 0

    init(kind: EncounterKind, position: CGPoint, horizontalDirection: CGFloat = 1) {
        self.kind = kind
        self.fixedX = position.x
        self.horizontalDirection = horizontalDirection
        self.visualNode = EncounterNode.makeVisualNode(for: kind)
        super.init()

        name = "encounter"
        self.position = position
        addChild(visualNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("EncounterNode does not support NSCoder initialization")
    }

    var duration: TimeInterval {
        switch kind {
        case .patrolOfficer: return GameConstants.officerDuration
        case .thief: return GameConstants.thiefDuration
        case .pidgeot: return GameConstants.pidgeotDuration
        }
    }

    func update(deltaTime: TimeInterval,
                targetX: CGFloat,
                targetY: CGFloat,
                routeWidth: CGFloat,
                sceneWidth: CGFloat) {
        elapsedTime += deltaTime

        switch kind {
        case .patrolOfficer:
            position.x = fixedX
            position.y = targetY + 60
        case .thief:
            position.x = fixedX
        case .pidgeot:
            position.x += GameConstants.pidgeotSpeed * horizontalDirection * CGFloat(deltaTime)
            position.y += GameConstants.pidgeotVerticalSpeed * CGFloat(deltaTime)
        }

        let halfWidth = visualNode.frame.width / 2
        let minimumX = sceneWidth / 2 - routeWidth / 2 + halfWidth
        let maximumX = sceneWidth / 2 + routeWidth / 2 - halfWidth
        position.x = min(max(position.x, minimumX), maximumX)
    }

    var hasExpired: Bool {
        return elapsedTime >= duration
    }

    var projectileEffect: ProjectileEffect? {
        switch kind {
        case .thief: return .damageHealth
        case .pidgeot: return .spoilFood
        case .patrolOfficer: return nil
        }
    }

    func shouldThrowProjectile(deltaTime: TimeInterval) -> Bool {
        guard projectileEffect != nil else { return false }
        projectileTimer += deltaTime

        let interval: TimeInterval
        let maximumProjectiles: Int
        switch kind {
        case .thief:
            interval = GameConstants.projectileInterval
            maximumProjectiles = 3
        case .pidgeot:
            interval = GameConstants.pidgeotProjectileInterval
            maximumProjectiles = 6
        case .patrolOfficer:
            return false
        }
        guard projectileTimer >= interval, projectilesThrown < maximumProjectiles else { return false }
        projectileTimer = 0
        projectilesThrown += 1
        return true
    }

    private static func makeVisualNode(for kind: EncounterKind) -> SKShapeNode {
        let node: SKShapeNode
        let title: String

        switch kind {
        case .patrolOfficer:
            node = SKShapeNode(rectOf: CGSize(width: 62, height: 76), cornerRadius: 12)
            node.fillColor = .systemBlue
            title = "OFFICER"
        case .thief:
            node = SKShapeNode(rectOf: CGSize(width: 58, height: 72), cornerRadius: 12)
            node.fillColor = .systemPurple
            title = "THIEF"
        case .pidgeot:
            node = SKShapeNode(ellipseOf: CGSize(width: 54, height: 42))
            node.fillColor = .systemTeal
            title = "PIDGEOT"
        }

        node.strokeColor = .white
        node.lineWidth = 3
        let label = SKLabelNode(text: title)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 9
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        node.addChild(label)
        return node
    }
}
