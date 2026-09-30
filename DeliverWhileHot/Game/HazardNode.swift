//
//  HazardNode.swift
//  DeliverWhileHot
//

import SpriteKit

final class HazardNode: SKNode {
    let definition: HazardDefinition
    private let visualNode: SKShapeNode
    private let baseX: CGFloat
    private let horizontalDirection: CGFloat
    private let startingPosition: CGPoint
    private var behaviorTime: CGFloat = 0
    private enum CatPhase {
        case wallApproach, warning, pouncing, threatening, retreating
    }
    private var catPhase: CatPhase = .wallApproach
    private var catPhaseTime: TimeInterval = 0
    private var warningNode: SKShapeNode?

    init(definition: HazardDefinition, position: CGPoint, horizontalDirection: CGFloat = 1) {
        self.definition = definition
        self.baseX = position.x
        self.horizontalDirection = horizontalDirection < 0 ? -1 : 1
        self.startingPosition = position
        self.visualNode = HazardNode.makeVisualNode(for: definition)
        super.init()

        name = "hazard"
        self.position = position
        if self.horizontalDirection < 0 {
            visualNode.xScale = -1
        }
        addChild(visualNode)

        if definition.kind == .cat {
            let warning = SKShapeNode(circleOfRadius: 10)
            warning.position = CGPoint(x: 0, y: definition.size.height / 2 + 36)
            warning.fillColor = SKColor(red: 0.76, green: 0.14, blue: 0.08, alpha: 0.94)
            warning.strokeColor = .white.withAlphaComponent(0.9)
            warning.lineWidth = 1.3
            warning.isHidden = true
            let mark = SKLabelNode(text: "!")
            mark.fontName = "AvenirNext-Heavy"
            mark.fontSize = 14
            mark.fontColor = .white
            mark.verticalAlignmentMode = .center
            warning.addChild(mark)
            addChild(warning)
            warningNode = warning
            warning.run(.repeatForever(.sequence([
                .group([.scale(to: 1.14, duration: 0.20), .fadeAlpha(to: 0.7, duration: 0.20)]),
                .group([.scale(to: 0.92, duration: 0.20), .fadeAlpha(to: 1, duration: 0.20)])
            ])), withKey: "catWarning")
        }

        let physicsBody: SKPhysicsBody
        switch definition.collisionShape {
        case let .rectangle(size):
            physicsBody = SKPhysicsBody(rectangleOf: size)
        case let .circle(radius):
            physicsBody = SKPhysicsBody(circleOfRadius: radius)
        }

        physicsBody.categoryBitMask = GameConstants.obstaclePhysicsCategory
        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask = GameConstants.playerPhysicsCategory
        physicsBody.affectedByGravity = false
        physicsBody.isDynamic = false
        self.physicsBody = physicsBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("HazardNode does not support NSCoder initialization")
    }

    func updateBehavior(deltaTime: TimeInterval,
                        routeWidth: CGFloat,
                        sceneWidth: CGFloat,
                        screenY: CGFloat,
                        playerY: CGFloat) {
        switch definition.movement {
        case let .drifting(amplitude, frequency):
            behaviorTime += CGFloat(deltaTime)
            let offset = sin(behaviorTime * frequency) * amplitude
            let halfRoute = routeWidth / 2 - definition.size.width / 2 - 8
            let minimumX = sceneWidth / 2 - halfRoute
            let maximumX = sceneWidth / 2 + halfRoute
            position.x = min(max(baseX + offset, minimumX), maximumX)

        case let .crossing(speed):
            position.x += horizontalDirection * speed * CGFloat(deltaTime)

        case let .pounce(upwardDistance, waitDuration, duration):
            catPhaseTime += deltaTime
            switch catPhase {
            case .wallApproach:
                // The cat rides down the roadside with the scrolling world, then telegraphs
                // only when it is close enough to threaten the rider.
                guard screenY <= playerY + 200 else { return }
                catPhase = .warning
                catPhaseTime = 0
                warningNode?.isHidden = false
            case .warning:
                guard catPhaseTime >= waitDuration else { return }
                catPhase = .pouncing
                catPhaseTime = 0
                warningNode?.isHidden = true
                playCatPounceAnimation(duration: duration)
            case .pouncing:
                let progress = min(1, CGFloat(catPhaseTime / duration))
                let easedProgress = 1 - (1 - progress) * (1 - progress)
                let inwardDistance = routeWidth / 2 + 8
                position.x = startingPosition.x + horizontalDirection * inwardDistance * easedProgress
                position.y = startingPosition.y + upwardDistance * easedProgress
                if progress >= 1 {
                    catPhase = .threatening
                    catPhaseTime = 0
                }
            case .threatening:
                if catPhaseTime >= 1.15 {
                    catPhase = .retreating
                    catPhaseTime = 0
                    if let sprite = visualNode.childNode(withName: "catSprite") as? SKSpriteNode {
                        let frames = GameSpriteSheet.catFrames
                        sprite.xScale = -1
                        let retreatFrames = Array(frames.dropFirst().reversed())
                        let fixedSize = sprite.size
                        let retreatLoop = SKAction.sequence([
                            .animate(with: retreatFrames,
                                     timePerFrame: 0.16,
                                     resize: false,
                                     restore: false),
                            .run { [weak sprite] in sprite?.size = fixedSize }
                        ])
                        sprite.run(.repeatForever(retreatLoop),
                                   withKey: "catRetreatAnimation")
                    }
                }
            case .retreating:
                position.x -= horizontalDirection * 104 * CGFloat(deltaTime)
                position.y += GameConstants.automaticScrollSpeed * 1.34 * CGFloat(deltaTime)
            }

        case .stationary:
            break
        }
    }

    func hasExitedSide(sceneWidth: CGFloat) -> Bool {
        position.x < -definition.size.width / 2 ||
            position.x > sceneWidth + definition.size.width / 2
    }

    private func playCatPounceAnimation(duration: TimeInterval) {
        guard let sprite = visualNode.childNode(withName: "catSprite") as? SKSpriteNode else { return }
        let frames = GameSpriteSheet.catFrames
        let fixedSize = sprite.size
        sprite.removeAction(forKey: "catPounceAnimation")
        sprite.run(.sequence([
            .animate(with: Array(frames.dropFirst()),
                     timePerFrame: duration / 3,
                     resize: false,
                     restore: false),
            .setTexture(frames[0], resize: false),
            .run { [weak sprite] in sprite?.size = fixedSize }
        ]), withKey: "catPounceAnimation")
    }

    private static func makeVisualNode(for definition: HazardDefinition) -> SKShapeNode {
        let node: SKShapeNode
        switch definition.collisionShape {
        case let .rectangle(size):
            node = SKShapeNode(rectOf: size, cornerRadius: 12)
        case let .circle(radius):
            node = SKShapeNode(circleOfRadius: radius)
        }

        // Keep the established hitbox shape as a transparent parent so the character art
        // can animate independently without changing the collision body.
        switch definition.kind {
        case .cat:
            node.fillColor = .clear
            node.strokeColor = .clear
            let frames = GameSpriteSheet.catFrames
            let sprite = SKSpriteNode(texture: frames[0])
            sprite.size = CGSize(width: GameConstants.playerSize.width * 0.68,
                                 height: GameConstants.playerSize.height * 0.69)
            sprite.name = "catSprite"
            node.addChild(sprite)
        case .cow:
            node.fillColor = .clear
            node.strokeColor = .clear
            let frames = GameSpriteSheet.horizontalFrames(
                imageName: "DeliverWhileHotHazardCow",
                frameCount: 4,
                insetPixels: 2,
                sourceSize: CGSize(width: 2_172, height: 724)
            )
            let sprite = SKSpriteNode(texture: frames[0])
            sprite.size = CGSize(width: definition.size.width / 0.95,
                                 height: definition.size.height / 0.49)
            sprite.run(.repeatForever(.animate(with: frames, timePerFrame: 0.22,
                                               resize: false, restore: false)))
            node.addChild(sprite)
        }
        return node
    }
}

enum GameSpriteSheet {
    static let catFrames = normalizedGridFrames(
        imageName: "DeliverWhileHotHazardCat",
        columns: 4,
        rows: 1,
        insetPixels: 2,
        artworkWidthFraction: 0.96
    )[0]

    static let thiefFrames = normalizedGridFrames(
        imageName: "DeliverWhileHotThiefAtlas",
        columns: 4,
        rows: 3,
        insetPixels: 2,
        artworkWidthFraction: 0.96
    )

    /// Crops one row from a regular grid. rowIndex is counted from the image's top edge;
    /// SpriteKit texture rectangles start at the bottom-left, so the y coordinate is flipped.
    static func gridRowFrames(imageName: String,
                              columns: Int,
                              rows: Int,
                              rowIndex: Int,
                              sourceSize: CGSize,
                              insetPixels: CGFloat = 2) -> [SKTexture] {
        let sheet = SKTexture(imageNamed: imageName)
        let cellWidth = sourceSize.width / CGFloat(columns)
        let cellHeight = sourceSize.height / CGFloat(rows)
        let yFromTop = CGFloat(rowIndex) * cellHeight + insetPixels
        let yFromBottom = sourceSize.height - yFromTop - (cellHeight - insetPixels * 2)

        return (0..<columns).map { column in
            let rect = CGRect(
                x: (CGFloat(column) * cellWidth + insetPixels) / sourceSize.width,
                y: yFromBottom / sourceSize.height,
                width: (cellWidth - insetPixels * 2) / sourceSize.width,
                height: (cellHeight - insetPixels * 2) / sourceSize.height
            )
            return SKTexture(rect: rect, in: sheet)
        }
    }

    static func horizontalFrames(imageName: String,
                                 frameCount: Int,
                                 insetPixels: CGFloat,
                                 sourceSize: CGSize,
                                 rowOrigin: CGFloat = 0,
                                 rowHeight: CGFloat = 1) -> [SKTexture] {
        let sheet = SKTexture(imageNamed: imageName)
        let cellWidth = sourceSize.width / CGFloat(frameCount)
        let insetX = insetPixels / sourceSize.width
        let insetY = insetPixels / sourceSize.height

        return (0..<frameCount).map { index in
            let rect = CGRect(x: (CGFloat(index) * cellWidth + insetPixels) / sourceSize.width,
                              y: rowOrigin + insetY,
                              width: (cellWidth - insetPixels * 2) / sourceSize.width,
                              height: rowHeight - insetY * 2)
            let texture = SKTexture(rect: rect, in: sheet)
            texture.filteringMode = .linear
            return texture
        }
    }

    /// Normalizes the visible character artwork inside each grid cell while preserving
    /// identical texture dimensions. The sprite node can therefore keep its size, center
    /// anchor, parent transform, and physics body throughout every pose change.
    static func normalizedGridFrames(imageName: String,
                                     columns: Int,
                                     rows: Int,
                                     insetPixels: CGFloat,
                                     artworkWidthFraction: CGFloat,
                                     baselineFraction: CGFloat = 0.06) -> [[SKTexture]] {
        let atlas = SKTexture(imageNamed: imageName).cgImage()
        let pixelWidth = atlas.width
        let pixelHeight = atlas.height
        let cellWidth = pixelWidth / columns
        let cellHeight = pixelHeight / rows
        let bytesPerPixel = 4
        let bytesPerRow = pixelWidth * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: pixelHeight * bytesPerRow)

        pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress,
                                          width: pixelWidth,
                                          height: pixelHeight,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                                            CGBitmapInfo.byteOrder32Big.rawValue) else { return }
            context.clear(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
            context.draw(atlas, in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        }

        let safeWidthFraction = min(max(artworkWidthFraction, 0.1), 0.96)
        let safeBaselineFraction = min(max(baselineFraction, 0), 0.2)
        return (0..<rows).map { row in
            (0..<columns).map { column in
                let cellOriginX = column * cellWidth
                let cellOriginY = row * cellHeight
                let inset = Int(insetPixels.rounded(.up))
                var minX = cellWidth
                var minY = cellHeight
                var maxX = -1
                var maxY = -1

                for y in inset..<(cellHeight - inset) {
                    for x in inset..<(cellWidth - inset) {
                        let alphaIndex = (cellOriginY + y) * bytesPerRow +
                            (cellOriginX + x) * bytesPerPixel + 3
                        if pixels[alphaIndex] > 10 {
                            minX = min(minX, x)
                            minY = min(minY, y)
                            maxX = max(maxX, x)
                            maxY = max(maxY, y)
                        }
                    }
                }

                guard maxX >= minX, maxY >= minY else {
                    let emptyContext = CGContext(data: nil,
                                                 width: cellWidth,
                                                 height: cellHeight,
                                                 bitsPerComponent: 8,
                                                 bytesPerRow: 0,
                                                 space: CGColorSpaceCreateDeviceRGB(),
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                                                    CGBitmapInfo.byteOrder32Big.rawValue)!
                    let texture = SKTexture(cgImage: emptyContext.makeImage()!)
                    texture.filteringMode = .linear
                    return texture
                }

                let cropRect = CGRect(x: cellOriginX + minX,
                                      y: cellOriginY + minY,
                                      width: maxX - minX + 1,
                                      height: maxY - minY + 1)
                guard let crop = atlas.cropping(to: cropRect) else {
                    let emptyContext = CGContext(data: nil,
                                                 width: cellWidth,
                                                 height: cellHeight,
                                                 bitsPerComponent: 8,
                                                 bytesPerRow: 0,
                                                 space: CGColorSpaceCreateDeviceRGB(),
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                                                    CGBitmapInfo.byteOrder32Big.rawValue)!
                    return SKTexture(cgImage: emptyContext.makeImage()!)
                }

                let canvas = CGSize(width: cellWidth, height: cellHeight)
                let targetWidth = canvas.width * safeWidthFraction
                let scale = targetWidth / CGFloat(crop.width)
                let targetHeight = CGFloat(crop.height) * scale
                let destination = CGRect(x: (canvas.width - targetWidth) / 2,
                                         y: canvas.height * safeBaselineFraction,
                                         width: targetWidth,
                                         height: targetHeight)
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue |
                    CGBitmapInfo.byteOrder32Big.rawValue
                let context = CGContext(data: nil,
                                        width: cellWidth,
                                        height: cellHeight,
                                        bitsPerComponent: 8,
                                        bytesPerRow: 0,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo)!
                context.clear(CGRect(origin: .zero, size: canvas))
                context.interpolationQuality = .high
                context.draw(crop, in: destination)
                let texture = SKTexture(cgImage: context.makeImage()!)
                texture.filteringMode = .linear
                return texture
            }
        }
    }
}
