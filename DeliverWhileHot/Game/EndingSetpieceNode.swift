import SpriteKit

/// Decorative, non-collidable dead-end wall and side doorway used only after the stage ends.
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
        let wallWidth = max(roadWidth + 18, sceneSize.width * 0.72)
        let doorX = sceneSize.width - 58
        let doorY = wallY - 158
        doorTarget = CGPoint(x: doorX - 8, y: doorY - 10)
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
        let houseFrontage = SKSpriteNode(texture: wallBand,
                                         size: CGSize(width: 256, height: 118))
        houseFrontage.position = CGPoint(x: sceneSize.width - 48, y: doorY + 16)
        houseFrontage.zRotation = .pi / 2
        houseFrontage.alpha = 0.96
        houseFrontage.zPosition = -1
        addChild(houseFrontage)

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

        let doorstep = SKShapeNode(rectOf: CGSize(width: 94, height: 34), cornerRadius: 3)
        doorstep.position = CGPoint(x: doorX - 12, y: doorY - 76)
        doorstep.fillColor = SKColor(red: 0.48, green: 0.30, blue: 0.16, alpha: 0.92)
        doorstep.strokeColor = SKColor(red: 0.24, green: 0.19, blue: 0.15, alpha: 0.95)
        doorstep.lineWidth = 2
        doorstep.zPosition = 2
        addChild(doorstep)

        let thresholdLight = SKShapeNode(ellipseOf: CGSize(width: 76, height: 23))
        thresholdLight.position = CGPoint(x: doorX - 20, y: doorY - 87)
        thresholdLight.fillColor = SKColor(red: 1, green: 0.58, blue: 0.20, alpha: 0.18)
        thresholdLight.strokeColor = .clear
        thresholdLight.zPosition = 1
        addChild(thresholdLight)

        addDoor(at: CGPoint(x: doorX, y: doorY))
        addArrow(at: CGPoint(x: doorX - 45, y: doorY + 9))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("EndingSetpieceNode does not support NSCoder initialization")
    }

    private func addDoor(at position: CGPoint) {
        let props = SKTexture(imageNamed: "DeliverWhileHotNeighborhoodProps")
        let doorway = SKTexture(rect: CGRect(x: 0.39, y: 0.53,
                                             width: 0.34, height: 0.47),
                                in: props)
        let frame = SKShapeNode(rectOf: CGSize(width: 72, height: 132), cornerRadius: 3)
        frame.position = position
        frame.fillColor = SKColor(red: 0.30, green: 0.25, blue: 0.19, alpha: 1)
        frame.strokeColor = SKColor(red: 0.63, green: 0.53, blue: 0.38, alpha: 1)
        frame.lineWidth = 4
        frame.zPosition = 3
        addChild(frame)

        let opening = SKSpriteNode(texture: doorway,
                                   size: CGSize(width: 66, height: 122))
        opening.position = CGPoint(x: position.x, y: position.y - 2)
        opening.zPosition = 4
        addChild(opening)

        let interior = SKShapeNode(rectOf: CGSize(width: 29, height: 106), cornerRadius: 1)
        interior.position = CGPoint(x: position.x + 7, y: position.y - 3)
        interior.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.08, alpha: 0.96)
        interior.strokeColor = .clear
        interior.zPosition = 5
        addChild(interior)

        let openDoor = SKShapeNode(rectOf: CGSize(width: 24, height: 104), cornerRadius: 2)
        openDoor.position = CGPoint(x: position.x - 10, y: position.y - 3)
        openDoor.zRotation = -0.15
        openDoor.fillColor = SKColor(red: 0.28, green: 0.19, blue: 0.13, alpha: 1)
        openDoor.strokeColor = SKColor(red: 0.58, green: 0.42, blue: 0.27, alpha: 1)
        openDoor.lineWidth = 2
        openDoor.zPosition = 6
        addChild(openDoor)
    }

    private func addArrow(at position: CGPoint) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -8, y: 0))
        path.addLine(to: CGPoint(x: 8, y: 0))
        path.move(to: CGPoint(x: 3, y: 5))
        path.addLine(to: CGPoint(x: 8, y: 0))
        path.addLine(to: CGPoint(x: 3, y: -5))

        let arrow = SKShapeNode(path: path)
        arrow.name = "endingDoorArrow"
        arrow.position = position
        arrow.strokeColor = SKColor(red: 1, green: 0.62, blue: 0.25, alpha: 0.92)
        arrow.lineWidth = 2.5
        arrow.lineCap = .round
        arrow.lineJoin = .round
        arrow.glowWidth = 0.8
        arrow.zPosition = 7
        addChild(arrow)
        arrow.run(.repeatForever(.sequence([
            .group([.fadeAlpha(to: 0.72, duration: 0.55), .scale(to: 0.97, duration: 0.55)]),
            .group([.fadeAlpha(to: 0.92, duration: 0.55), .scale(to: 1.03, duration: 0.55)])
        ])), withKey: "doorArrowPulse")
    }
}
