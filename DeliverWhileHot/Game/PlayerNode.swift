//
//  PlayerNode.swift
//  DeliverWhileHot
//

import SpriteKit

enum PlayerVisualState {
    case normal
    case burning
}

enum PlayerAction {
    case riding
    case eating
    case hit
    case throwing
    case blocking
}

final class PlayerNode: SKNode {
    private let spriteNode = SKSpriteNode()
    private(set) var visualState: PlayerVisualState = .normal
    private(set) var actionState: PlayerAction = .riding
    private var targetAngle = CGFloat.pi

    var isEating: Bool {
        actionState == .eating
    }

    var isThrowing: Bool {
        actionState == .throwing
    }

    var isBlocking: Bool {
        actionState == .blocking
    }

    override init() {
        super.init()
        name = "player"

        let body = SKPhysicsBody(rectangleOf: GameConstants.playerSize)
        body.categoryBitMask = GameConstants.playerPhysicsCategory
        body.collisionBitMask = 0
        body.contactTestBitMask = GameConstants.obstaclePhysicsCategory
        body.affectedByGravity = false
        body.allowsRotation = false
        body.isDynamic = true
        physicsBody = body

        addChild(spriteNode)
        spriteNode.zRotation = .pi
        updateAnimation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("PlayerNode does not support NSCoder initialization")
    }

    func setBurning(_ burning: Bool) {
        visualState = burning ? .burning : .normal
        updateAnimation()
    }

    @discardableResult
    func startEating() -> Bool {
        guard actionState == .riding else { return false }
        actionState = .eating
        updateAnimation()
        return true
    }

    func playHitAnimation() {
        actionState = .hit
        updateAnimation()
    }

    @discardableResult
    func startBlocking() -> Bool {
        guard actionState == .riding else { return false }
        actionState = .blocking
        updateAnimation()
        return true
    }

    func stopBlocking() {
        guard actionState == .blocking else { return }
        actionState = .riding
        updateAnimation()
    }

    @discardableResult
    func startThrowing(onRelease: @escaping () -> Void) -> Bool {
        guard actionState == .riding else { return false }
        actionState = .throwing
        updateAnimation(onThrowRelease: onRelease)
        return true
    }

    func playHealthRecoveryAnimation() {
        childNode(withName: "healingEffect")?.removeFromParent()
        addChild(HealingEffectNode())
    }

    func setMovement(horizontal: CGFloat, vertical: CGFloat) {
        let clampedHorizontal = max(-1, min(1, horizontal))
        let isMoving = hypot(horizontal, vertical) > 0.01
        var facingHorizontal = clampedHorizontal
        var facingVertical = max(-1, min(1, vertical))

        // The road scrolls toward the rider, so backward input must not make
        // the artwork face down-screen. Clamp its heading to the forward arc:
        // 9 o'clock → 12 o'clock → 3 o'clock.
        if facingVertical < 0 {
            if abs(facingHorizontal) > 0.01 {
                facingVertical = 0
            } else {
                facingHorizontal = 0
                facingVertical = 1
            }
        }

        // The artwork faces up when zRotation is π. Rotate the whole rider
        // toward the joystick direction instead of applying only a small bank.
        let requestedAngle = isMoving
            ? atan2(facingVertical, facingHorizontal) + .pi / 2
            : CGFloat.pi
        guard abs(requestedAngle - targetAngle) > 0.001 else { return }
        targetAngle = requestedAngle

        spriteNode.run(.rotate(toAngle: requestedAngle,
                               duration: 0.09,
                               shortestUnitArc: true),
                       withKey: "movementTilt")
    }

    func stopAnimations() {
        spriteNode.removeAllActions()
    }

    func playEndingPreparation() {
        spriteNode.removeAction(forKey: "endingPreparation")
        let crouch = SKAction.group([
            .scaleY(to: 0.84, duration: 0.12),
            .moveBy(x: 0, y: -4, duration: 0.12)
        ])
        crouch.timingMode = .easeOut
        let recover = SKAction.group([
            .scaleY(to: 1, duration: 0.20),
            .moveBy(x: 0, y: 4, duration: 0.20)
        ])
        recover.timingMode = .easeInEaseOut
        spriteNode.run(.sequence([crouch, recover]), withKey: "endingPreparation")
    }

    func showCollisionFeedback() {
        spriteNode.removeAction(forKey: "collisionFeedback")
        let feedback = SKAction.sequence([
            .run { [weak self] in self?.spriteNode.color = .red },
            .wait(forDuration: GameConstants.collisionFeedbackDuration),
            .run { [weak self] in
                self?.spriteNode.color = .white
                self?.spriteNode.colorBlendFactor = 0
            }
        ])
        spriteNode.run(feedback, withKey: "collisionFeedback")
    }

    private func updateAnimation(onThrowRelease: (() -> Void)? = nil) {
        spriteNode.removeAllActions()

        let textureName: String
        let frameCount: Int
        switch (visualState, actionState) {
        case (.normal, .riding):
            textureName = "DeliverWhileHotPlayerDefault"
            frameCount = 4
        case (.burning, .riding):
            textureName = "DeliverWhileHotPlayerBurning"
            frameCount = 4
        case (.normal, .eating):
            textureName = "DeliverWhileHotPlayerEating"
            frameCount = 5
        case (.burning, .eating):
            textureName = "DeliverWhileHotPlayerEatingBurning"
            frameCount = 5
        case (.normal, .hit):
            textureName = "DeliverWhileHotPlayerHit"
            frameCount = 5
        case (.burning, .hit):
            textureName = "DeliverWhileHotPlayerHitBurning"
            frameCount = 5
        case (.normal, .throwing), (.burning, .throwing):
            textureName = "DeliverWhileHotPlayerMolotovThrow"
            frameCount = 5
        case (_, .blocking):
            textureName = "DeliverWhileHotPlayerBlock"
            frameCount = 5
        }

        let sheet = SKTexture(imageNamed: textureName)
        let frames = (0..<frameCount).map { index in
            let frameWidth = 1.0 / CGFloat(frameCount)
            return SKTexture(rect: CGRect(x: CGFloat(index) * frameWidth,
                                          y: 0,
                                          width: frameWidth,
                                          height: 1),
                             in: sheet)
        }

        spriteNode.texture = frames.first
        let textureSize = frames[0].size()
        let maximumDimension: CGFloat = 112
        let scale = min(maximumDimension / textureSize.width,
                        maximumDimension / textureSize.height)
        spriteNode.size = CGSize(width: textureSize.width * scale,
                                 height: textureSize.height * scale)
        spriteNode.colorBlendFactor = 0

        if actionState == .blocking {
            let frameDuration = GameConstants.blockFrameDuration
            let blockingFrames = Array(frames.prefix(4))
            let animation = SKAction.sequence([
                .animate(with: blockingFrames,
                         timePerFrame: frameDuration,
                         resize: false,
                         restore: false),
                .setTexture(blockingFrames.last ?? frames[0])
            ])
            spriteNode.run(animation, withKey: "blockAnimation")
        } else if actionState == .throwing {
            let frameDuration = GameConstants.molotovThrowFrameDuration
            let releaseAction = SKAction.run { onThrowRelease?() }
            let animation = SKAction.sequence([
                .animate(with: Array(frames.prefix(4)),
                         timePerFrame: frameDuration,
                         resize: false,
                         restore: false),
                releaseAction,
                .animate(with: [frames[4]],
                         timePerFrame: frameDuration,
                         resize: false,
                         restore: false),
                .run { [weak self] in
                    guard let self else { return }
                    self.actionState = .riding
                    self.updateAnimation()
                }
            ])
            spriteNode.run(animation, withKey: "throwAnimation")
        } else if actionState == .eating || actionState == .hit {
            let frameDuration: TimeInterval = actionState == .hit
                ? GameConstants.hitAnimationFrameDuration
                : 0.16
            let animation = SKAction.animate(with: frames,
                                             timePerFrame: frameDuration,
                                             resize: false,
                                             restore: false)
            spriteNode.run(.sequence([
                animation,
                .run { [weak self] in
                    guard let self else { return }
                    self.actionState = .riding
                    self.updateAnimation()
                }
            ]), withKey: actionState == .hit ? "hitAnimation" : "eatingAnimation")
        }
    }
}
