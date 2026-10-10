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
                run(.playSoundFileNamed(GameConstants.catSpawnSoundName,
                                        waitForCompletion: false))
            case .warning:
                guard catPhaseTime >= waitDuration else { return }
                catPhase = .pouncing
                catPhaseTime = 0
                warningNode?.isHidden = true
                playCatPounceAnimation(duration: duration)
                run(.playSoundFileNamed(GameConstants.catAttackSoundName,
                                        waitForCompletion: false))
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
            sprite.size = CGSize(width: GameConstants.playerSize.width * 0.78,
                                 height: GameConstants.playerSize.height * 0.75)
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
    static let endingPreparationFrames = normalizedGridFrames(
        imageName: "EndingPreparationAtlas",
        columns: 4,
        rows: 1,
        insetPixels: 3,
        artworkWidthFraction: 0.94,
        artworkHeightFraction: 0.92,
        fixedArtworkHeightFraction: 0.86,
        maximumArtworkWidthFraction: 0.94,
        outputCanvasWidth: 512,
        preserveSourceScale: false
    )[0]

    static let endingJumpFrames = normalizedGridFrames(
        imageName: "EndingJumpAtlas",
        columns: 5,
        rows: 1,
        insetPixels: 3,
        artworkWidthFraction: 0.94,
        artworkHeightFraction: 0.92,
        fixedArtworkHeightFraction: 0.86,
        maximumArtworkWidthFraction: 0.94,
        outputCanvasWidth: 512,
        preserveSourceScale: false
    )[0]

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
        artworkWidthFraction: 0.90,
        artworkHeightFraction: 0.80,
        fixedArtworkHeightFraction: 0.78,
        maximumArtworkWidthFraction: 0.78,
        outputCanvasWidth: 352,
        preserveSourceScale: false,
        // These poses cross the nominal 256-pixel columns. Rectangles are measured
        // from the top-left of the 1024 × 1536 source, then normalized for loading.
        sourceRegions: [
            5: CGRect(x: 244, y: 573, width: 244, height: 396),
            6: CGRect(x: 484, y: 603, width: 260, height: 362),
            7: CGRect(x: 754, y: 603, width: 268, height: 362),
            8: CGRect(x: 10, y: 1026, width: 230, height: 460),
            9: CGRect(x: 241, y: 990, width: 247, height: 470),
            10: CGRect(x: 484, y: 1030, width: 260, height: 430),
            11: CGRect(x: 754, y: 1030, width: 268, height: 430)
        ].mapValues { CGRect(x: $0.minX / 1024, y: $0.minY / 1536,
                             width: $0.width / 1024, height: $0.height / 1536) },
        excludedRegions: [
            7: [CGRect(x: 754, y: 603, width: 61, height: 152)],
            10: [CGRect(x: 484, y: 1030, width: 18, height: 230),
                 CGRect(x: 730, y: 1030, width: 14, height: 120)],
            11: [CGRect(x: 754, y: 1030, width: 69, height: 200)]
        ].mapValues { regions in
            regions.map { CGRect(x: $0.minX / 1024, y: $0.minY / 1536,
                                 width: $0.width / 1024, height: $0.height / 1536) }
        }
    )

    /// Warm the CPU-side atlas normalization before the first encounter is spawned.
    static func prepareEncounterFrames() {
        _ = catFrames
        _ = thiefFrames
        _ = endingPreparationFrames
        _ = endingJumpFrames
    }

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
                                     baselineFraction: CGFloat = 0.06,
                                     artworkHeightFraction: CGFloat? = nil,
                                     fixedArtworkHeightFraction: CGFloat? = nil,
                                     maximumArtworkWidthFraction: CGFloat? = nil,
                                     outputCanvasWidth: CGFloat? = nil,
                                     preserveSourceScale: Bool = false,
                                     sourceRegions: [Int: CGRect] = [:],
                                     excludedRegions: [Int: [CGRect]] = [:]) -> [[SKTexture]] {
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
        let safeHeightFraction = artworkHeightFraction.map { min(max($0, 0.1), 0.96) }
        let safeFixedArtworkHeightFraction = fixedArtworkHeightFraction.map {
            min(max($0, 0.1), 0.96)
        }
        let safeMaximumArtworkWidthFraction = maximumArtworkWidthFraction.map {
            min(max($0, 0.1), 0.96)
        }
        let imageRect = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)
        func pixelRect(_ normalized: CGRect) -> CGRect {
            CGRect(x: normalized.minX * CGFloat(pixelWidth),
                   y: normalized.minY * CGFloat(pixelHeight),
                   width: normalized.width * CGFloat(pixelWidth),
                   height: normalized.height * CGFloat(pixelHeight)).integral.intersection(imageRect)
        }
        let exclusionsByPose = excludedRegions.mapValues { $0.map(pixelRect) }

        // Measure visible pixels first. Most sheets use a shared source scale; the thief
        // opts into a bounded visible size because its attack poses spread wider.
        let bounds: [[CGRect?]] = (0..<rows).map { row in
            (0..<columns).map { column -> CGRect? in
                let region = sourceRegions[row * columns + column].map(pixelRect)
                    ?? CGRect(x: column * cellWidth, y: row * cellHeight,
                              width: cellWidth, height: cellHeight)
                let cellOriginX = Int(region.minX)
                let cellOriginY = Int(region.minY)
                let scanWidth = Int(region.width)
                let scanHeight = Int(region.height)
                let inset = Int(insetPixels.rounded(.up))
                var minX = scanWidth
                var minY = scanHeight
                var maxX = -1
                var maxY = -1

                for y in inset..<(scanHeight - inset) {
                    for x in inset..<(scanWidth - inset) {
                        let sourcePoint = CGPoint(x: cellOriginX + x, y: cellOriginY + y)
                        if exclusionsByPose[row * columns + column]?.contains(where: {
                            $0.contains(sourcePoint)
                        }) == true {
                            continue
                        }
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

                guard maxX >= minX, maxY >= minY else { return nil }
                return CGRect(x: cellOriginX + minX, y: cellOriginY + minY,
                              width: maxX - minX + 1, height: maxY - minY + 1)
            }
        }

        let canvas = CGSize(width: outputCanvasWidth ?? CGFloat(cellWidth),
                            height: CGFloat(cellHeight))
        let targetWidth = canvas.width * safeWidthFraction
        let maximumArtworkHeight = canvas.height * (safeHeightFraction ?? safeWidthFraction)
        let tallestPose = bounds.flatMap { $0 }.compactMap { $0?.height }.max() ?? 1
        let sharedScale = min(targetWidth / CGFloat(cellWidth), maximumArtworkHeight / tallestPose)

        return (0..<rows).map { row in
            (0..<columns).map { column in
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue |
                    CGBitmapInfo.byteOrder32Big.rawValue
                let context = CGContext(data: nil,
                                        width: Int(canvas.width),
                                        height: Int(canvas.height),
                                        bitsPerComponent: 8,
                                        bytesPerRow: 0,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo)!
                context.clear(CGRect(origin: .zero, size: canvas))
                guard let bounds = bounds[row][column],
                      let crop = atlas.cropping(to: bounds) else {
                    return SKTexture(cgImage: context.makeImage()!)
                }
                let scale: CGFloat
                if preserveSourceScale {
                    scale = sharedScale
                } else if let safeFixedArtworkHeightFraction {
                    // Match pose height, but cap width too: the attack art spreads its
                    // arms farther than the idle art, which otherwise reads as a growth
                    // spurt despite the sprite node itself keeping a fixed size.
                    let heightScale = canvas.height * safeFixedArtworkHeightFraction /
                        CGFloat(crop.height)
                    let widthScale = safeMaximumArtworkWidthFraction.map {
                        canvas.width * $0 / CGFloat(crop.width)
                    } ?? .greatestFiniteMagnitude
                    scale = min(heightScale, widthScale)
                } else if safeHeightFraction != nil {
                    scale = min(targetWidth / CGFloat(crop.width),
                                maximumArtworkHeight / CGFloat(crop.height))
                } else {
                    // Preserve existing sizing for other callers such as the cat atlas.
                    scale = targetWidth / CGFloat(crop.width)
                }
                let renderedWidth = CGFloat(crop.width) * scale
                let renderedHeight = CGFloat(crop.height) * scale
                // Keep horizontal placement relative to the source cell. Centering each
                // silhouette separately would slide the torso when an arm reaches out.
                let destinationX = preserveSourceScale || safeFixedArtworkHeightFraction != nil
                    ? (canvas.width - CGFloat(cellWidth) * scale) / 2
                        + (bounds.minX - CGFloat(column * cellWidth)) * scale
                    : (canvas.width - renderedWidth) / 2
                let destination = CGRect(x: destinationX,
                                         y: canvas.height * safeBaselineFraction,
                                         width: renderedWidth,
                                         height: renderedHeight)
                context.interpolationQuality = .high
                if let exclusions = excludedRegions[row * columns + column] {
                    // Source rectangles count down from the top; CGContext counts up.
                    let clip = CGMutablePath()
                    clip.addRect(CGRect(origin: .zero, size: canvas))
                    for excluded in exclusions.map(pixelRect) {
                        let cutout = CGRect(x: destination.minX + (excluded.minX - bounds.minX) * scale,
                                            y: destination.minY + (bounds.maxY - excluded.maxY) * scale,
                                            width: excluded.width * scale,
                                            height: excluded.height * scale)
                        clip.addRect(cutout)
                    }
                    context.addPath(clip)
                    context.clip(using: .evenOdd)
                }
                context.draw(crop, in: destination)
                let texture = SKTexture(cgImage: context.makeImage()!)
                texture.filteringMode = .linear
                return texture
            }
        }
    }
}
