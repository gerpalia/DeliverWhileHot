//
//  GameNodeFactory.swift
//  DeliverWhileHot
//

import SpriteKit

struct GameNodeFactory {
    func makeRoad(width: CGFloat, height: CGFloat) -> SKShapeNode {
        let road = SKShapeNode(rectOf: CGSize(width: width, height: height))
        road.fillColor = GameConstants.roadColor
        road.strokeColor = .clear
        road.position = CGPoint(x: width / 2, y: height / 2)
        return road
    }

    func makeLaneMarkers(width: CGFloat, height: CGFloat) -> [SKShapeNode] {
        stride(from: 70, through: height - 70, by: 140).map { y in
            let dash = SKShapeNode(rectOf: CGSize(width: 8, height: 70), cornerRadius: 4)
            dash.fillColor = .white.withAlphaComponent(0.28)
            dash.strokeColor = .clear
            dash.position = CGPoint(x: width / 2, y: y)
            return dash
        }
    }

    func makeBoundaries(width: CGFloat, routeWidth: CGFloat, height: CGFloat) -> [SKShapeNode] {
        [width / 2 - routeWidth / 2, width / 2 + routeWidth / 2].map { x in
            let boundary = SKShapeNode(rectOf: CGSize(width: 10, height: height))
            boundary.fillColor = .yellow.withAlphaComponent(0.8)
            boundary.strokeColor = .clear
            boundary.position = CGPoint(x: x, y: height / 2)
            return boundary
        }
    }

    func makePlayer() -> PlayerNode {
        PlayerNode()
    }

    func makeHazard(definition: HazardDefinition, position: CGPoint) -> HazardNode {
        HazardNode(definition: definition, position: position)
    }

    func makeBonus(kind: BonusKind, position: CGPoint) -> BonusNode {
        BonusNode(kind: kind, position: position)
    }

    func makeDestination(width: CGFloat, routeWidth: CGFloat, height: CGFloat) -> SKShapeNode {
        let destination = SKShapeNode(rectOf: CGSize(width: routeWidth - 36,
                                                       height: GameConstants.destinationHeight),
                                      cornerRadius: 18)
        destination.name = "destination"
        destination.fillColor = GameConstants.destinationColor.withAlphaComponent(0.35)
        destination.strokeColor = GameConstants.destinationColor
        destination.lineWidth = 5
        destination.position = CGPoint(x: width / 2,
                                       y: height - GameConstants.destinationTopInset)

        let label = SKLabelNode(text: "DELIVERY")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        destination.addChild(label)
        return destination
    }
}
