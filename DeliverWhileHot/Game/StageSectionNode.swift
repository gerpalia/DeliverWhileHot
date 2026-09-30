//
//  StageSectionNode.swift
//  DeliverWhileHot
//

import SpriteKit

/// A decorative roadside section. It has no physics and never participates in gameplay.
final class StageSectionNode: SKNode {
    private struct DecalDefinition {
        let column: Int
        let row: Int
        let widthScale: CGFloat
        let heightScale: CGFloat
        let alpha: CGFloat
    }

    private static let concreteTileOrder = [0, 2, 1, 3, 1, 0, 3, 2, 0, 3, 1, 2, 3, 0, 2, 1]
    private static let decalDefinitions = [
        DecalDefinition(column: 0, row: 3, widthScale: 1.08, heightScale: 1.08, alpha: 0.72), // crack
        DecalDefinition(column: 2, row: 3, widthScale: 0.96, heightScale: 0.96, alpha: 0.58), // grime
        DecalDefinition(column: 0, row: 2, widthScale: 0.90, heightScale: 0.90, alpha: 0.82), // weeds
        DecalDefinition(column: 1, row: 2, widthScale: 0.94, heightScale: 0.94, alpha: 0.60), // stain
        DecalDefinition(column: 2, row: 2, widthScale: 0.62, heightScale: 0.62, alpha: 0.90), // can
        DecalDefinition(column: 3, row: 2, widthScale: 0.82, heightScale: 0.82, alpha: 0.82), // rubble
        DecalDefinition(column: 2, row: 1, widthScale: 1.02, heightScale: 1.02, alpha: 0.72), // crack
        DecalDefinition(column: 3, row: 1, widthScale: 0.88, heightScale: 0.88, alpha: 0.82), // weeds
        DecalDefinition(column: 2, row: 0, widthScale: 0.62, heightScale: 0.62, alpha: 0.84)  // paper
    ]

    private let sectionHeight: CGFloat
    private let sideWidth: CGFloat
    private let sidewalkWidth: CGFloat
    private let frontageWidth: CGFloat
    private let leftFrontageX: CGFloat
    private let rightFrontageX: CGFloat
    private let leftSidewalkX: CGFloat
    private let rightSidewalkX: CGFloat
    private let leftOuterSidewalkX: CGFloat
    private let rightOuterSidewalkX: CGFloat

    init(index: Int, width: CGFloat, routeWidth: CGFloat, sectionHeight: CGFloat) {
        self.sectionHeight = sectionHeight
        sideWidth = max(0, (width - routeWidth) / 2)
        sidewalkWidth = min(width * GameConstants.sidewalkWidthRatio, sideWidth)
        frontageWidth = max(0, sideWidth - sidewalkWidth)
        leftFrontageX = frontageWidth / 2
        rightFrontageX = width - frontageWidth / 2
        leftSidewalkX = frontageWidth + sidewalkWidth / 2
        rightSidewalkX = width - frontageWidth - sidewalkWidth / 2
        leftOuterSidewalkX = frontageWidth + sidewalkWidth * 0.35
        rightOuterSidewalkX = width - frontageWidth - sidewalkWidth * 0.35
        super.init()

        name = "stageSection-\(index)"
        addSidewalkSurface(index: index)
        addSidewalkDecals(index: index)
        addCurbDamage(index: index)
        addWalls(index: index)
        addProps(index: index)
        addPuddle(index: index)
        addResident(index: index)
        addChalkDecal(index: index)
        addSemaphore(index: index)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("StageSectionNode does not support NSCoder initialization")
    }

    private func addSidewalkSurface(index: Int) {
        let sheet = SKTexture(imageNamed: "DeliverWhileHotSidewalkConcrete")
        let tileCount = max(1, Int(ceil(sectionHeight / sidewalkWidth)))
        let tileHeight = sectionHeight / CGFloat(tileCount)

        for side in 0..<2 {
            let x = side == 0 ? leftSidewalkX : rightSidewalkX
            let sequenceOffset = (index * tileCount + side * 7) % Self.concreteTileOrder.count

            for tileIndex in 0..<tileCount {
                let orderIndex = (sequenceOffset + tileIndex) % Self.concreteTileOrder.count
                let tileNumber = Self.concreteTileOrder[orderIndex]
                let column = tileNumber % 2
                let row = tileNumber / 2
                let texture = gridTexture(sheet,
                                          column: column,
                                          row: row,
                                          columns: 2,
                                          rows: 2,
                                          insetPixels: 2,
                                          sourceSize: CGSize(width: 1_254, height: 1_254))
                let tile = SKSpriteNode(texture: texture)
                tile.size = CGSize(width: sidewalkWidth, height: max(tileHeight - 0.45, 1))
                tile.position = CGPoint(x: x,
                                        y: CGFloat(tileIndex) * tileHeight + tileHeight / 2)
                tile.zPosition = -79
                addChild(tile)
            }
        }
    }

    private func addSidewalkDecals(index: Int) {
        let sheet = SKTexture(imageNamed: "DeliverWhileHotSidewalkDecals")

        for side in 0..<2 where (index + side).isMultiple(of: 2) {
            let definitionIndex = (index * 3 + side * 5) % Self.decalDefinitions.count
            let definition = Self.decalDefinitions[definitionIndex]
            let texture = gridTexture(sheet,
                                      column: definition.column,
                                      row: definition.row,
                                      columns: 4,
                                      rows: 4,
                                      insetPixels: 3,
                                      sourceSize: CGSize(width: 1_254, height: 1_254))
            let decal = SKSpriteNode(texture: texture)
            decal.size = CGSize(width: sidewalkWidth * definition.widthScale,
                                height: sidewalkWidth * definition.heightScale)
            let outerX = side == 0 ? leftOuterSidewalkX : rightOuterSidewalkX
            let verticalSeed = CGFloat((index * 37 + side * 19) % 63) / 100
            decal.position = CGPoint(x: outerX,
                                     y: sectionHeight * (0.18 + verticalSeed))
            decal.zRotation = side == 0 ? -0.08 : 0.08
            decal.alpha = definition.alpha
            decal.zPosition = -76
            addChild(decal)
        }
    }

    private func addCurbDamage(index: Int) {
        guard index.isMultiple(of: 4) else { return }
        let sheet = SKTexture(imageNamed: "DeliverWhileHotSidewalkDecals")
        let texture = gridTexture(sheet,
                                  column: 1,
                                  row: index.isMultiple(of: 8) ? 3 : 0,
                                  columns: 4,
                                  rows: 4,
                                  insetPixels: 3,
                                  sourceSize: CGSize(width: 1_254, height: 1_254))
        let side = (index / 4) % 2
        let roadEdgeX = side == 0
            ? leftSidewalkX + sidewalkWidth / 2
            : rightSidewalkX - sidewalkWidth / 2
        let curbDamage = SKSpriteNode(texture: texture)
        curbDamage.size = CGSize(width: sidewalkWidth * 0.72,
                                 height: sidewalkWidth * 0.72)
        curbDamage.position = CGPoint(x: roadEdgeX + (side == 0 ? -sidewalkWidth * 0.18 : sidewalkWidth * 0.18),
                                      y: sectionHeight * 0.64)
        curbDamage.zRotation = side == 0 ? -.pi / 2 : .pi / 2
        curbDamage.zPosition = -69
        addChild(curbDamage)
    }

    private func addWalls(index: Int) {
        let sheet = SKTexture(imageNamed: "DeliverWhileHotPaintedWalls")
        let row = CGFloat(index % 4) * 0.25
        let texture = SKTexture(rect: CGRect(x: 0, y: row, width: 1, height: 0.24), in: sheet)

        for x in [leftFrontageX, rightFrontageX] {
            let wall = SKSpriteNode(texture: texture)
            wall.size = CGSize(width: sectionHeight * 0.92,
                               height: max(frontageWidth * 0.96, 1))
            wall.position = CGPoint(x: x, y: sectionHeight / 2)
            wall.zRotation = .pi / 2
            wall.zPosition = -60
            addChild(wall)
        }
    }

    private func addProps(index: Int) {
        let sheet = SKTexture(imageNamed: "DeliverWhileHotNeighborhoodProps")
        let pipe = SKTexture(imageNamed: "DeliverWhileHotLeakingPipe")
        let fence = crop(sheet, x: 0.0, y: 0.53, width: 0.39, height: 0.47)
        let doorway = crop(sheet, x: 0.39, y: 0.53, width: 0.34, height: 0.47)
        let dumpster = crop(sheet, x: 0.73, y: 0.53, width: 0.27, height: 0.47)
        let lamp = crop(sheet, x: 0.0, y: 0.0, width: 0.39, height: 0.53)
        let grill = crop(sheet, x: 0.39, y: 0.0, width: 0.34, height: 0.53)
        let utilityPole = crop(sheet, x: 0.73, y: 0.0, width: 0.27, height: 0.53)

        let frontageChoices: [(SKTexture, CGFloat, CGFloat, CGFloat)] = [
            (index % 3 == 0 ? doorway : fence,
             leftFrontageX,
             sectionHeight * 0.50,
             126),
            (index % 4 == 1 ? dumpster : utilityPole,
             rightFrontageX,
             sectionHeight * 0.53,
             118),
            (index % 5 == 2 ? grill : pipe,
             index.isMultiple(of: 2) ? leftFrontageX : rightFrontageX,
             sectionHeight * 0.80,
             104)
        ]

        for (texture, x, y, desiredHeight) in frontageChoices {
            let prop = SKSpriteNode(texture: texture)
            let maxWidth = max(sideWidth * 1.02, 1)
            let scale = min(maxWidth / texture.size().width,
                            desiredHeight / texture.size().height)
            prop.setScale(scale)
            prop.position = CGPoint(x: x, y: y)
            prop.zPosition = -40
            addChild(prop)
        }

        let streetlamp = SKSpriteNode(texture: lamp)
        let lampScale = min(max(sidewalkWidth * 0.85, 1) / lamp.size().width,
                            112 / lamp.size().height)
        streetlamp.setScale(lampScale)
        streetlamp.position = CGPoint(x: index.isMultiple(of: 2) ? leftOuterSidewalkX : rightOuterSidewalkX,
                                      y: sectionHeight * 0.24)
        streetlamp.zPosition = -30
        addChild(streetlamp)
    }

    private func addPuddle(index: Int) {
        let sheet = SKTexture(imageNamed: "DeliverWhileHotPuddleDecals")
        let puddleIndex = index % 6
        let puddle = gridTexture(sheet,
                                 column: puddleIndex % 2,
                                 row: puddleIndex / 2,
                                 columns: 2,
                                 rows: 3,
                                 insetPixels: 4,
                                 sourceSize: CGSize(width: 1_536, height: 1_024))
        let node = SKSpriteNode(texture: puddle)
        let puddleWidth = max(sidewalkWidth * 1.14, 1)
        let puddleAspectRatio = puddle.size().height / max(puddle.size().width, 1)
        node.size = CGSize(width: puddleWidth,
                           height: max(puddleWidth * puddleAspectRatio, 1))
        node.position = CGPoint(x: index.isMultiple(of: 2) ? leftSidewalkX : rightSidewalkX,
                                y: sectionHeight * 0.12)
        node.alpha = 0.72
        node.zPosition = -50
        addChild(node)
    }

    private func addResident(index: Int) {
        guard index % 3 == 1 else { return }
        let sheet = SKTexture(imageNamed: "DeliverWhileHotNeighborhoodResidents")
        let resident = crop(sheet,
                             x: CGFloat(index % 4) * 0.25,
                             y: 0,
                             width: 0.25,
                             height: 1)
        let node = SKSpriteNode(texture: resident)
        node.size = CGSize(width: max(sidewalkWidth * 0.95, 1),
                           height: max(sidewalkWidth * 2.3, 1))
        node.position = CGPoint(x: index.isMultiple(of: 2) ? rightOuterSidewalkX : leftOuterSidewalkX,
                                y: sectionHeight * 0.38)
        node.zPosition = -20
        addChild(node)
    }

    private func addChalkDecal(index: Int) {
        guard index % 5 == 3 else { return }
        let sheet = SKTexture(imageNamed: "DeliverWhileHotChalkDecals")
        let decal = crop(sheet,
                          x: CGFloat(index % 3) / 3,
                          y: 0,
                          width: 1.0 / 3,
                          height: 1)
        let node = SKSpriteNode(texture: decal)
        node.size = CGSize(width: max(sidewalkWidth * 1.15, 1),
                           height: max(sidewalkWidth * 0.8, 1))
        node.position = CGPoint(x: index.isMultiple(of: 2) ? leftSidewalkX : rightSidewalkX,
                                y: sectionHeight * 0.70)
        node.alpha = 0.55
        node.zPosition = -50
        addChild(node)
    }

    private func addSemaphore(index: Int) {
        guard index % 6 == 4 else { return }
        let semaphore = SKSpriteNode(imageNamed: "DeliverWhileHotRedSemaphore")
        semaphore.size = CGSize(width: max(frontageWidth * 0.9, 1),
                                height: max(frontageWidth * 2.4, 1))
        semaphore.position = CGPoint(x: index.isMultiple(of: 2) ? leftFrontageX : rightFrontageX,
                                     y: sectionHeight * 0.72)
        semaphore.zPosition = -20
        addChild(semaphore)
    }

    private func crop(_ texture: SKTexture,
                      x: CGFloat,
                      y: CGFloat,
                      width: CGFloat,
                      height: CGFloat) -> SKTexture {
        SKTexture(rect: CGRect(x: x, y: y, width: width, height: height), in: texture)
    }

    private func gridTexture(_ texture: SKTexture,
                             column: Int,
                             row: Int,
                             columns: Int,
                             rows: Int,
                             insetPixels: CGFloat,
                             sourceSize: CGSize) -> SKTexture {
        let cellWidth = 1 / CGFloat(columns)
        let cellHeight = 1 / CGFloat(rows)
        let insetX = insetPixels / sourceSize.width
        let insetY = insetPixels / sourceSize.height
        let rect = CGRect(x: CGFloat(column) * cellWidth + insetX,
                          y: CGFloat(row) * cellHeight + insetY,
                          width: cellWidth - insetX * 2,
                          height: cellHeight - insetY * 2)
        let croppedTexture = SKTexture(rect: rect, in: texture)
        croppedTexture.filteringMode = .linear
        return croppedTexture
    }
}
