//
//  GameConstants.swift
//  DeliverWhileHot
//

import SpriteKit

enum GameConstants {
    static let playerPhysicsCategory: UInt32 = 1 << 0
    static let obstaclePhysicsCategory: UInt32 = 1 << 1

    static let routeHeightMultiplier: CGFloat = 3.2
    static let minimumRouteHeight: CGFloat = 1_800
    static let routeWidthRatio: CGFloat = 0.82
    static let maximumRouteWidth: CGFloat = 420

    static let playerSize = CGSize(width: 44, height: 58)
    static let playerCornerRadius: CGFloat = 10
    static let playerStartHeight: CGFloat = 120
    static let movementSmoothing: CGFloat = 0.16
    static let automaticScrollSpeed: CGFloat = 120
    static let topTouchExclusionHeight: CGFloat = 150
    static let bottomTouchExclusionHeight: CGFloat = 100
    static let collisionFeedbackDuration: TimeInterval = 0.18
    static let collisionCooldown: TimeInterval = 0.75

    static let obstacleRadius: CGFloat = 28
    static let destinationHeight: CGFloat = 96
    static let destinationTopInset: CGFloat = 140

    static let routeColor = SKColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1)
    static let roadColor = SKColor(red: 0.22, green: 0.24, blue: 0.30, alpha: 1)
    static let playerColor = SKColor(red: 0.25, green: 0.85, blue: 0.95, alpha: 1)
    static let obstacleColor = SKColor(red: 0.95, green: 0.30, blue: 0.25, alpha: 1)
    static let destinationColor = SKColor(red: 0.35, green: 0.95, blue: 0.45, alpha: 1)
}
