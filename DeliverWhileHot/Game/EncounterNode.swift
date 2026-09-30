//
//  EncounterNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum EncounterKind: Equatable {
    case thief
    case pidgeot
}

final class EncounterNode: SKNode {
    private static let thiefArtworkSize = CGSize(width: 80, height: 108)
    let kind: EncounterKind
    private let visualNode: SKShapeNode
    private let artworkNode: SKSpriteNode?
    private let fixedX: CGFloat
    private let entryStartX: CGFloat
    private let entryDuration: TimeInterval
    private let horizontalDirection: CGFloat
    private let thiefFrameRows: [[SKTexture]]?
    private let warningIndicator: SKShapeNode?
    private var entryElapsedTime: TimeInterval = 0
    private var projectileTimer: TimeInterval = 0
    private(set) var projectilesThrown = 0
    private var reachedScreenEdge = false
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
            thief.size = Self.thiefArtworkSize
            thief.xScale = horizontalDirection < 0 ? -1 : 1
            self.artworkNode = thief

            let indicator = SKShapeNode(circleOfRadius: 11)
            indicator.position = CGPoint(x: 0, y: 62)
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
            // Use the full wing cycle; the former up/up pair barely appeared animated.
            let flapFrames = [frames[0], frames[1], frames[2], frames[1]]
            let pigeon = SKSpriteNode(texture: flapFrames[0])
            pigeon.size = CGSize(width: 62, height: 56)
            pigeon.xScale = horizontalDirection < 0 ? -1 : 1
            pigeon.run(.repeatForever(.animate(with: flapFrames, timePerFrame: 0.14,
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
            artworkNode.zPosition = 1
            addChild(artworkNode)
        }
        if let warningIndicator {
            warningIndicator.zPosition = 2
            addChild(warningIndicator)
        }
        if kind == .thief {
            startThiefEntryAnimation()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("EncounterNode does not support NSCoder initialization")
    }

    func update(deltaTime: TimeInterval,
                targetX: CGFloat,
                targetY: CGFloat,
                routeWidth: CGFloat,
                sceneWidth: CGFloat) {
        switch kind {
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
                    artworkNode?.size = Self.thiefArtworkSize
                    // Telegraph the first knife as soon as the thief has entered view.
                    projectileTimer = GameConstants.projectileInterval
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
        } else if kind != .thief || (!isEntering && !isRetreating) {
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
        case .pidgeot:
            return reachedScreenEdge
        }
    }

    func hasExitedSide(sceneWidth: CGFloat) -> Bool {
        guard kind == .thief || kind == .pidgeot else { return false }
        let halfWidth = kind == .thief ? (artworkNode?.size.width ?? 0) / 2 : 34
        return position.x < -halfWidth || position.x > sceneWidth + halfWidth
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
            // Keep the first human hazard's attack unambiguous while its separate
            // projectile and animation are being established: this encounter throws knives.
            let effect: ProjectileEffect = .knifeDamage
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
        // This atlas pose already contains a detached knife. Use the clean follow-through
        // pose instead so the scene's actual ProjectileNode is the only knife after release.
        artworkNode.texture = frames[3]
        artworkNode.size = fixedSize
        artworkNode.run(.sequence([
            .setTexture(frames[3], resize: false),
            .wait(forDuration: 0.30),
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

        switch kind {
        case .thief:
            node = SKShapeNode(rectOf: CGSize(width: 58, height: 72), cornerRadius: 12)
            node.fillColor = .clear
            node.strokeColor = .clear
        case .pidgeot:
            node = SKShapeNode(ellipseOf: CGSize(width: 54, height: 42))
            node.fillColor = .clear
            node.strokeColor = .clear
        }

        return node
    }
}
