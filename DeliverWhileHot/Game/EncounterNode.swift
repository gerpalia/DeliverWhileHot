//
//  EncounterNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum EncounterKind: Equatable {
    case patrolOfficer
    case thief
    case pidgeot
}

final class EncounterNode: SKNode {
    let kind: EncounterKind
    private let visualNode: SKShapeNode
    private let artworkNode: SKSpriteNode?
    private let fixedX: CGFloat
    private let entryStartX: CGFloat
    private let entryDuration: TimeInterval
    private let horizontalDirection: CGFloat
    private let thiefFrameRows: [[SKTexture]]?
    private let warningIndicator: SKShapeNode?
    private var elapsedTime: TimeInterval = 0
    private var entryElapsedTime: TimeInterval = 0
    private var projectileTimer: TimeInterval = 0
    private(set) var projectilesThrown = 0
    private var reachedScreenEdge = false
    private(set) var isOfficerRetreating = false
    private var officerRetreatDirection: CGFloat = 1
    private var warningRemaining: TimeInterval = 0
    private var pendingThiefEffect: ProjectileEffect?
    private(set) var didBeginThiefWarningThisFrame = false
    private(set) var isRetreating = false

    init(kind: EncounterKind,
         position: CGPoint,
         horizontalDirection: CGFloat = 1,
         entryStartX: CGFloat? = nil,
         entryDuration: TimeInterval = 0) {
        self.kind = kind
        self.fixedX = position.x
        self.entryStartX = entryStartX ?? position.x
        self.entryDuration = entryDuration
        self.horizontalDirection = horizontalDirection
        self.visualNode = EncounterNode.makeVisualNode(for: kind)
        if kind == .thief {
            let rows = GameSpriteSheet.thiefFrames
            self.thiefFrameRows = rows
            let thief = SKSpriteNode(texture: rows[0][0])
            thief.size = CGSize(width: GameConstants.playerSize.width * 0.72,
                                 height: GameConstants.playerSize.height * 0.92)
            thief.xScale = horizontalDirection < 0 ? -1 : 1
            self.artworkNode = thief

            let indicator = SKShapeNode(circleOfRadius: 11)
            indicator.position = CGPoint(x: 0, y: 49)
            indicator.fillColor = SKColor(red: 0.76, green: 0.14, blue: 0.08, alpha: 0.94)
            indicator.strokeColor = SKColor(red: 1, green: 0.88, blue: 0.68, alpha: 0.96)
            indicator.lineWidth = 1.5
            indicator.isHidden = true
            let exclamation = SKLabelNode(text: "!")
            exclamation.fontName = "AvenirNext-Heavy"
            exclamation.fontSize = 16
            exclamation.fontColor = .white
            exclamation.verticalAlignmentMode = .center
            exclamation.position.y = -1
            indicator.addChild(exclamation)
            self.warningIndicator = indicator
        } else if kind == .pidgeot {
            self.thiefFrameRows = nil
            self.warningIndicator = nil
            let frames = GameSpriteSheet.horizontalFrames(
                imageName: "DeliverWhileHotHazardPigeon",
                frameCount: 4,
                insetPixels: 2,
                sourceSize: CGSize(width: 2_172, height: 724),
                rowOrigin: 0.32,
                rowHeight: 0.68
            )
            let flapFrames = [frames[0], frames[3]]
            let pigeon = SKSpriteNode(texture: flapFrames[0])
            pigeon.size = CGSize(width: 54, height: 49)
            pigeon.run(.repeatForever(.animate(with: flapFrames, timePerFrame: 0.24,
                                               resize: false, restore: false)))
            self.artworkNode = pigeon
        } else {
            self.thiefFrameRows = nil
            self.warningIndicator = nil
            self.artworkNode = nil
        }
        super.init()

        name = "encounter"
        self.position = position
        addChild(visualNode)
        if let artworkNode {
            addChild(artworkNode)
        }
        if let warningIndicator {
            addChild(warningIndicator)
        }
        if kind == .thief {
            startThiefEntryAnimation()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("EncounterNode does not support NSCoder initialization")
    }

    var duration: TimeInterval {
        switch kind {
        case .patrolOfficer: return GameConstants.officerDuration
        case .thief: return .infinity
        case .pidgeot: return .infinity
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
            if isOfficerRetreating {
                position.x += officerRetreatDirection * 170 * CGFloat(deltaTime)
                position.y += GameConstants.automaticScrollSpeed * 1.34 * CGFloat(deltaTime)
            } else {
                position.x = fixedX
            }
        case .thief:
            let wasEntering = isEntering
            if entryElapsedTime < entryDuration {
                entryElapsedTime = min(entryDuration, entryElapsedTime + deltaTime)
                let progress = entryDuration == 0 ? 1 : entryElapsedTime / entryDuration
                position.x = entryStartX + (fixedX - entryStartX) * CGFloat(progress)
                position.y -= GameConstants.automaticScrollSpeed * CGFloat(deltaTime)
                if wasEntering && !isEntering, let frames = thiefFrameRows?[0] {
                    artworkNode?.removeAction(forKey: "thiefEntryAnimation")
                    artworkNode?.texture = frames[3]
                    artworkNode?.size = CGSize(width: GameConstants.playerSize.width * 0.72,
                                               height: GameConstants.playerSize.height * 0.92)
                }
            } else if isRetreating {
                position.x -= horizontalDirection * 126 * CGFloat(deltaTime)
            } else {
                position.x = fixedX
            }
        case .pidgeot:
            position.x += GameConstants.pidgeotSpeed * horizontalDirection * CGFloat(deltaTime)
            position.y += GameConstants.pidgeotVerticalSpeed * CGFloat(deltaTime)
        }

        if case .pidgeot = kind {
            let margin = visualNode.frame.width / 2
            reachedScreenEdge = horizontalDirection > 0
                ? position.x > sceneWidth + margin
                : position.x < -margin
        } else if (kind != .thief || (!isEntering && !isRetreating)) &&
                    (kind != .patrolOfficer || !isOfficerRetreating) {
            let halfWidth = visualNode.frame.width / 2
            let minimumX = sceneWidth / 2 - routeWidth / 2 + halfWidth
            let maximumX = sceneWidth / 2 + routeWidth / 2 - halfWidth
            position.x = min(max(position.x, minimumX), maximumX)
        }
    }

    var hasExpired: Bool {
        switch kind {
        case .thief:
            return false
        case .patrolOfficer:
            return false
        case .pidgeot:
            return reachedScreenEdge
        }
    }

    func hasExitedSide(sceneWidth: CGFloat) -> Bool {
        guard kind == .thief || kind == .pidgeot || kind == .patrolOfficer else { return false }
        let halfWidth = kind == .thief ? (artworkNode?.size.width ?? 0) / 2 : 34
        return position.x < -halfWidth || position.x > sceneWidth + halfWidth
    }

    var hasReachedDuration: Bool { elapsedTime >= duration }

    func beginOfficerRetreat(sceneWidth: CGFloat) {
        guard kind == .patrolOfficer, !isOfficerRetreating else { return }
        isOfficerRetreating = true
        officerRetreatDirection = fixedX < sceneWidth / 2 ? -1 : 1
    }

    /// Advances attack timing and returns an effect only on the release frame.
    func projectileToThrow(deltaTime: TimeInterval) -> ProjectileEffect? {
        didBeginThiefWarningThisFrame = false
        guard !isEntering else { return nil }
        guard !isRetreating else { return nil }

        switch kind {
        case .thief:
            if let pendingThiefEffect {
                warningRemaining = max(0, warningRemaining - deltaTime)
                guard warningRemaining == 0 else { return nil }
                self.pendingThiefEffect = nil
                projectileTimer = 0
                projectilesThrown += 1
                playThiefReleaseAnimation(for: pendingThiefEffect)
                return pendingThiefEffect
            }

            if projectilesThrown >= 3 {
                beginThiefRetreat()
                return nil
            }

            projectileTimer += deltaTime
            guard projectileTimer >= GameConstants.projectileInterval,
                  projectilesThrown < 3 else { return nil }
            projectileTimer = 0
            let effect: ProjectileEffect = Bool.random() ? .knifeDamage : .burningDamage
            pendingThiefEffect = effect
            warningRemaining = GameConstants.thiefWarningDuration
            didBeginThiefWarningThisFrame = true
            playThiefWindUp(for: effect)
            return nil
        case .pidgeot:
            projectileTimer += deltaTime
            guard projectileTimer >= GameConstants.pidgeotProjectileInterval,
                  projectilesThrown < 6 else { return nil }
            projectileTimer = 0
            projectilesThrown += 1
            return .spoilFood
        case .patrolOfficer:
            return nil
        }
    }

    var isEntering: Bool {
        entryElapsedTime < entryDuration
    }

    private func startThiefEntryAnimation() {
        guard let frames = thiefFrameRows?[0], let artworkNode else { return }
        let fixedSize = artworkNode.size
        let entryLoop = SKAction.sequence([
            .animate(with: Array(frames.prefix(3)),
                     timePerFrame: 0.16,
                     resize: false,
                     restore: false),
            .run { [weak artworkNode] in artworkNode?.size = fixedSize }
        ])
        artworkNode.run(.repeatForever(entryLoop),
                        withKey: "thiefEntryAnimation")
    }

    private func playThiefWindUp(for effect: ProjectileEffect) {
        guard let artworkNode, let warningIndicator else { return }
        let rowIndex = effect == .burningDamage ? 2 : 1
        guard let frames = thiefFrameRows?[rowIndex], frames.count >= 4 else { return }

        warningIndicator.isHidden = false
        warningIndicator.fillColor = effect == .burningDamage
            ? SKColor(red: 0.98, green: 0.38, blue: 0.08, alpha: 0.96)
            : SKColor(red: 0.76, green: 0.14, blue: 0.08, alpha: 0.94)
        warningIndicator.removeAllActions()
        warningIndicator.setScale(0.82)
        warningIndicator.alpha = 1
        warningIndicator.run(.repeatForever(.sequence([
            .group([.scale(to: 1.12, duration: 0.16), .fadeAlpha(to: 0.72, duration: 0.16)]),
            .group([.scale(to: 0.92, duration: 0.16), .fadeAlpha(to: 1, duration: 0.16)])
        ])), withKey: "thiefWarningPulse")

        artworkNode.removeAction(forKey: "thiefEntryAnimation")
        artworkNode.removeAction(forKey: "thiefReleaseAnimation")
        let fixedSize = artworkNode.size
        artworkNode.run(.sequence([
            .setTexture(frames[0], resize: false),
            .wait(forDuration: 0.16),
            .setTexture(frames[1], resize: false),
            .run { [weak artworkNode] in artworkNode?.size = fixedSize }
        ]), withKey: "thiefWindUp")
    }

    private func playThiefReleaseAnimation(for effect: ProjectileEffect) {
        guard let artworkNode, let warningIndicator else { return }
        let rowIndex = effect == .burningDamage ? 2 : 1
        guard let frames = thiefFrameRows?[rowIndex], frames.count >= 4 else { return }

        warningIndicator.isHidden = true
        warningIndicator.removeAllActions()
        artworkNode.removeAction(forKey: "thiefWindUp")
        let fixedSize = artworkNode.size
        artworkNode.texture = frames[3] // Follow-through frame has no baked-in flying projectile.
        artworkNode.size = fixedSize
        artworkNode.run(.sequence([
            .wait(forDuration: 0.24),
            .setTexture(thiefFrameRows?[0][3] ?? frames[0], resize: false),
            .run { [weak artworkNode] in artworkNode?.size = fixedSize }
        ]), withKey: "thiefReleaseAnimation")
    }

    private func beginThiefRetreat() {
        guard !isRetreating else { return }
        isRetreating = true
        warningIndicator?.isHidden = true
        artworkNode?.removeAllActions()
        if let frames = thiefFrameRows?[0] {
            artworkNode?.xScale = horizontalDirection < 0 ? 1 : -1
            let fixedSize = artworkNode?.size ?? .zero
            let retreatLoop = SKAction.sequence([
                .animate(with: Array(frames.prefix(3)),
                         timePerFrame: 0.16,
                         resize: false,
                         restore: false),
                .run { [weak artworkNode] in artworkNode?.size = fixedSize }
            ])
            artworkNode?.run(.repeatForever(retreatLoop),
                             withKey: "thiefRetreatAnimation")
        }
    }

    private static func makeVisualNode(for kind: EncounterKind) -> SKShapeNode {
        let node: SKShapeNode
        let title: String

        switch kind {
        case .patrolOfficer:
            node = SKShapeNode(rectOf: CGSize(width: 62, height: 76), cornerRadius: 12)
            node.fillColor = SKColor(red: 0.19, green: 0.21, blue: 0.23, alpha: 0.96)
            title = "OFFICER"
        case .thief:
            node = SKShapeNode(rectOf: CGSize(width: 58, height: 72), cornerRadius: 12)
            node.fillColor = .clear
            node.strokeColor = .clear
            title = ""
        case .pidgeot:
            node = SKShapeNode(ellipseOf: CGSize(width: 54, height: 42))
            node.fillColor = .clear
            node.strokeColor = .clear
            title = "PIDGEOT"
        }

        if kind == .patrolOfficer {
            node.strokeColor = SKColor(red: 0.55, green: 0.47, blue: 0.36, alpha: 0.82)
            node.lineWidth = 1.5
            let label = SKLabelNode(text: title)
            label.fontName = "AvenirNext-Bold"
            label.fontSize = 8
            label.fontColor = SKColor(red: 0.91, green: 0.86, blue: 0.73, alpha: 1)
            label.verticalAlignmentMode = .center
            node.addChild(label)
        }
        return node
    }
}
