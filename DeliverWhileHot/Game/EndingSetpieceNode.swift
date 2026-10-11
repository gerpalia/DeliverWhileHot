import SpriteKit

/// Decorative, non-collidable dead-end wall and open side entrance used only after the stage ends.
final class EndingSetpieceNode: SKNode {
    let doorTarget: CGPoint
    let scooterImpactPoint: CGPoint
    let wallCenterY: CGFloat

    init(sceneSize: CGSize, roadWidth: CGFloat) {
        // In SpriteKit, positive Y points upward. Keep the barricade ahead of the doorway
        // so the rider gets a visible run-up and a late jump, while the door stays inset.
        let wallY = sceneSize.height * 0.70
        wallCenterY = wallY
        let wallHeight: CGFloat = 92
        // Keep the barricade within the road so it doesn't swallow the sidewalk entrance.
        let wallWidth = roadWidth + 16
        let sideWidth = max(0, (sceneSize.width - roadWidth) / 2)
        let sidewalkWidth = min(sceneSize.width * GameConstants.sidewalkWidthRatio, sideWidth)
        let frontageWidth = max(1, sideWidth - sidewalkWidth)
        // Keep the entrance inside the frontage instead of centering it on the
        // outermost edge, where the opening can be clipped on portrait screens.
        let doorX = sceneSize.width - frontageWidth * 0.72
        let doorY = wallY - 158
        doorTarget = CGPoint(x: doorX, y: doorY)
        scooterImpactPoint = CGPoint(x: sceneSize.width / 2,
                                     y: wallY - wallHeight / 2 - 38)
        super.init()

        name = "endingSetpiece"
        zPosition = 8

        let barrier = SKShapeNode(rectOf: CGSize(width: wallWidth, height: wallHeight),
                                  cornerRadius: 5)
        barrier.position = CGPoint(x: sceneSize.width / 2, y: wallY)
        barrier.fillColor = SKColor(red: 0.22, green: 0.23, blue: 0.25, alpha: 1)
        barrier.strokeColor = SKColor(red: 0.48, green: 0.46, blue: 0.42, alpha: 1)
        barrier.lineWidth = 4
        barrier.zPosition = 0
        addChild(barrier)

        let wallTexture = SKTexture(imageNamed: "DeliverWhileHotPaintedWalls")
        let wallBand = SKTexture(rect: CGRect(x: 0, y: 0.75, width: 1, height: 0.24),
                                 in: wallTexture)
        let facade = SKSpriteNode(texture: wallBand,
                                  size: CGSize(width: wallWidth - 6, height: wallHeight - 8))
        facade.position = barrier.position
        facade.alpha = 0.88
        facade.zPosition = 1
        addChild(facade)

        // A worn warning band makes the road-ending wall read as solid, not as an exit.
        let warningBand = SKShapeNode(rectOf: CGSize(width: wallWidth - 10, height: 9))
        warningBand.position = CGPoint(x: sceneSize.width / 2, y: wallY - wallHeight / 2 + 7)
        warningBand.fillColor = SKColor(red: 0.68, green: 0.43, blue: 0.15, alpha: 0.9)
        warningBand.strokeColor = .clear
        warningBand.zPosition = 2
        addChild(warningBand)

        addOpenHouseEntrance(at: CGPoint(x: doorX, y: doorY),
                             frontageWidth: frontageWidth,
                             wallTexture: wallBand)
        addArrow(at: CGPoint(x: doorX - frontageWidth * 0.32, y: doorY + 14),
                 frontageWidth: frontageWidth)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("EndingSetpieceNode does not support NSCoder initialization")
    }

    private func addOpenHouseEntrance(at position: CGPoint,
                                      frontageWidth: CGFloat,
                                      wallTexture: SKTexture) {
        let openingHeight: CGFloat = 108
        let wallTop = wallCenterY + 60
        let wallBottom = position.y - openingHeight / 2 - 120
        let upperLength = max(1, wallTop - (position.y + openingHeight / 2))
        let lowerLength = max(1, (position.y - openingHeight / 2) - wallBottom)
        let wallX = position.x

        addSideWallSection(texture: wallTexture,
                           center: CGPoint(x: wallX,
                                           y: position.y + openingHeight / 2 + upperLength / 2),
                           length: upperLength,
                           frontageWidth: frontageWidth)
        addSideWallSection(texture: wallTexture,
                           center: CGPoint(x: wallX,
                                           y: position.y - openingHeight / 2 - lowerLength / 2),
                           length: lowerLength,
                           frontageWidth: frontageWidth)

        // The opening is a single dark gap cut into the wall: no door sprite or leaf.
        let opening = SKShapeNode(rectOf: CGSize(width: frontageWidth * 0.82,
                                                 height: openingHeight))
        opening.position = position
        opening.fillColor = SKColor(red: 0.035, green: 0.027, blue: 0.022, alpha: 1)
        opening.strokeColor = .clear
        opening.zPosition = 4
        addChild(opening)

        // The supplied image is a portrait reference containing the road,
        // sidewalk, wall, and open entrance. Use only the frontage crop so it
        // reads as part of the house rather than a second full-screen background.
        let reference = SKTexture(imageNamed: "DeliverWhileHotEntranceReference")
        let entranceCrop = SKTexture(rect: CGRect(x: 0.74,
                                                   y: 0.18,
                                                   width: 0.26,
                                                   height: 0.52),
                                      in: reference)
        let entrance = SKSpriteNode(texture: entranceCrop)
        let entranceWidth = max(frontageWidth * 0.96, 1)
        entrance.size = CGSize(width: entranceWidth,
                               height: entranceWidth * entranceCrop.size().height /
                                   max(entranceCrop.size().width, 1))
        entrance.position = position
        entrance.zPosition = 5
        addChild(entrance)

        // A faint amber pool falls from the doorway across the sidewalk toward the road.
        let lightSpill = SKShapeNode(ellipseOf: CGSize(width: 106, height: 142))
        lightSpill.position = CGPoint(x: position.x - 24, y: position.y - 62)
        lightSpill.fillColor = SKColor(red: 1, green: 0.55, blue: 0.18, alpha: 0.20)
        lightSpill.strokeColor = .clear
        lightSpill.glowWidth = 15
        lightSpill.zPosition = 2.5
        addChild(lightSpill)

        let interiorGlow = SKShapeNode(ellipseOf: CGSize(width: frontageWidth * 0.72,
                                                         height: 74))
        interiorGlow.position = CGPoint(x: position.x - frontageWidth * 0.10,
                                        y: position.y - 16)
        interiorGlow.fillColor = SKColor(red: 1, green: 0.61, blue: 0.25, alpha: 0.24)
        interiorGlow.strokeColor = .clear
        interiorGlow.glowWidth = 11
        interiorGlow.zPosition = 5
        addChild(interiorGlow)
    }

    private func addSideWallSection(texture: SKTexture,
                                    center: CGPoint,
                                    length: CGFloat,
                                    frontageWidth: CGFloat) {
        let wall = SKSpriteNode(texture: texture,
                                size: CGSize(width: length, height: frontageWidth))
        wall.position = center
        wall.zRotation = .pi / 2
        wall.alpha = 0.98
        wall.zPosition = 3
        addChild(wall)
    }

    private func addArrow(at position: CGPoint, frontageWidth: CGFloat) {
        let arrow = SKSpriteNode(imageNamed: "DeliverWhileHotEndingArrow")
        arrow.name = "endingDoorArrow"
        arrow.position = position
        let arrowWidth = min(max(frontageWidth * 0.76, 24), 52)
        arrow.size = CGSize(width: arrowWidth,
                            height: arrowWidth * 1024 / 1536)
        arrow.zPosition = 7
        addChild(arrow)
        arrow.run(.repeatForever(.sequence([
            .group([.fadeAlpha(to: 0.72, duration: 0.55), .scale(to: 0.97, duration: 0.55)]),
            .group([.fadeAlpha(to: 0.92, duration: 0.55), .scale(to: 1.03, duration: 0.55)])
        ])), withKey: "doorArrowPulse")
    }
}
