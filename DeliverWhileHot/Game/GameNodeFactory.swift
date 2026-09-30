//
//  GameNodeFactory.swift
//  DeliverWhileHot
//

import SpriteKit

struct GameNodeFactory {
    func makeRoad(sceneWidth: CGFloat, roadWidth: CGFloat, height: CGFloat) -> SKNode {
        let road = SKNode()
        let texture = SKTexture(imageNamed: "DeliverWhileHotRoadAsphaltTexture")
        let tileHeight = roadWidth
        let tileCount = Int(ceil(height / tileHeight))

        for index in 0..<tileCount {
            let tile = SKSpriteNode(texture: texture,
                                    size: CGSize(width: roadWidth, height: tileHeight))
            tile.position = CGPoint(x: sceneWidth / 2,
                                    y: CGFloat(index) * tileHeight + tileHeight / 2)
            tile.zPosition = -100
            road.addChild(tile)
        }

        return road
    }

    func makeRoadsideStrips(width: CGFloat, routeWidth: CGFloat, height: CGFloat) -> [SKShapeNode] {
        let sideWidth = max(0, (width - routeWidth) / 2)
        let sidewalkWidth = min(width * GameConstants.sidewalkWidthRatio, sideWidth)
        let frontageWidth = max(0, sideWidth - sidewalkWidth)

        let frontages = [frontageWidth / 2, width - frontageWidth / 2].map { x in
            let frontage = SKShapeNode(rectOf: CGSize(width: frontageWidth, height: height))
            frontage.fillColor = GameConstants.frontageColor
            frontage.strokeColor = .clear
            frontage.position = CGPoint(x: x, y: height / 2)
            frontage.zPosition = -90
            return frontage
        }

        let sidewalks = [frontageWidth + sidewalkWidth / 2,
                         width - frontageWidth - sidewalkWidth / 2].map { x in
            let sidewalk = SKShapeNode(rectOf: CGSize(width: sidewalkWidth, height: height))
            sidewalk.fillColor = GameConstants.sidewalkColor
            sidewalk.strokeColor = .clear
            sidewalk.position = CGPoint(x: x, y: height / 2)
            sidewalk.zPosition = -80
            return sidewalk
        }

        let curbColor = SKColor(red: 0.32, green: 0.33, blue: 0.36, alpha: 1)
        let curbs = [width / 2 - routeWidth / 2, width / 2 + routeWidth / 2].map { x in
            let curb = SKShapeNode(rectOf: CGSize(width: 5, height: height))
            curb.fillColor = curbColor
            curb.strokeColor = .clear
            curb.position = CGPoint(x: x, y: height / 2)
            curb.zPosition = -70
            return curb
        }

        return frontages + sidewalks + curbs
    }

    func makeLaneMarkers(width: CGFloat, height: CGFloat) -> [SKShapeNode] {
        stride(from: 70, through: height - 70, by: 140).map { y in
            let dash = SKShapeNode(rectOf: CGSize(width: 8, height: 70), cornerRadius: 4)
            dash.fillColor = .white.withAlphaComponent(0.28)
            dash.strokeColor = .clear
            dash.position = CGPoint(x: width / 2, y: y)
            dash.zPosition = -10
            return dash
        }
    }

    func makePlayer() -> PlayerNode {
        PlayerNode()
    }

    func makeHazard(definition: HazardDefinition,
                    position: CGPoint,
                    horizontalDirection: CGFloat = 1) -> HazardNode {
        HazardNode(definition: definition,
                   position: position,
                   horizontalDirection: horizontalDirection)
    }

    func makeBonus(kind: BonusKind, position: CGPoint) -> BonusNode {
        BonusNode(kind: kind, position: position)
    }

    func makeDestination(width: CGFloat, routeWidth: CGFloat, height: CGFloat) -> SKShapeNode {
        let destination = SKShapeNode(rectOf: CGSize(width: routeWidth - 36,
                                                       height: GameConstants.destinationHeight),
                                      cornerRadius: 18)
        destination.name = "destination"
        // This shape is only a trigger volume; the ending set piece supplies the artwork.
        destination.fillColor = .clear
        destination.strokeColor = .clear
        destination.position = CGPoint(x: width / 2,
                                       y: height - GameConstants.destinationTopInset)
        return destination
    }
}
