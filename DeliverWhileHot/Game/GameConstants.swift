//
//  GameConstants.swift
//  DeliverWhileHot
//

import SpriteKit

enum GameConstants {
    static let playerPhysicsCategory: UInt32 = 1 << 0
    static let obstaclePhysicsCategory: UInt32 = 1 << 1

    // A deterministic thirty-second route gives each planned encounter room to read.
    static let targetStageDuration: TimeInterval = 30
    static let minimumRouteHeight: CGFloat = 3_600
    static let routeWidthRatio: CGFloat = 0.60
    static let sidewalkWidthRatio: CGFloat = 0.10
    static let navigableWidthRatio: CGFloat = 0.80
    static let maximumRouteWidth: CGFloat = 420

    static let playerSize = CGSize(width: 44, height: 58)
    static let playerCornerRadius: CGFloat = 10
    static let playerStartHeight: CGFloat = 120
    static let movementSmoothing: TimeInterval = 0.12
    static let playerMovementSpeed: CGFloat = 275
    static let playerVerticalMovementSpeed: CGFloat = 190
    static let automaticScrollSpeed: CGFloat = 130
    static let topTouchExclusionHeight: CGFloat = 150
    static let bottomTouchExclusionHeight: CGFloat = 150
    static let joystickSafeZoneRightEdge: CGFloat = 144
    static let joystickSafeZoneTopEdge: CGFloat = 135
    static let collisionFeedbackDuration: TimeInterval = 0.18
    static let collisionCooldown: TimeInterval = 0.75
    static let hitInvincibilityDuration: TimeInterval = 1.5
    static let hitAnimationFrameDuration: TimeInterval = 0.16
    static let hitStopDuration: TimeInterval = 0.28
    static let bonusStopDuration: TimeInterval = 0.16
    static let perfectParryWindow: TimeInterval = 0.12
    static let blockImpactCooldown: TimeInterval = 0.30
    static let eatCooldown: TimeInterval = 3.0
    static let molotovCooldown: TimeInterval = 6.0
    static let startingMolotovCount = 3
    static let maximumMolotovCount = 5
    static let parrySlowMotionDuration: TimeInterval = 0.18
    static let parrySlowMotionFactor: TimeInterval = 0.25
    static let blockFrameDuration: TimeInterval = 0.08
    static let molotovThrowFrameDuration: TimeInterval = 0.14
    static let molotovProjectileSpeed: CGFloat = 420
    static let thiefSpawnTime: TimeInterval = 14
    static let thiefWarningDuration: TimeInterval = 0.72
    static let thiefKnifeSpeed: CGFloat = 360
    static let thiefMolotovSpeed: CGFloat = 260
    static let sideHazardEntryDuration: TimeInterval = 1.15
    static let pidgeotSpawnTime: TimeInterval = 7.5
    static let projectileSpeed: CGFloat = 280
    static let projectileInterval: TimeInterval = 1.1
    static let pidgeotSpeed: CGFloat = 110
    static let pidgeotVerticalSpeed: CGFloat = 0
    static let pidgeotProjectileInterval: TimeInterval = 0.55
    static let earlyHazardSpawnInterval: TimeInterval = 2.4
    static let midHazardSpawnInterval: TimeInterval = 2.1
    static let lateHazardSpawnInterval: TimeInterval = 1.8
    static let hitSoundName = "player_scream_extended.wav"
    static let bonusPickupSoundName = "bonus_pickup.wav"
    static let healthRecoverySoundName = "health_recovery.caf"
    static let catSpawnSoundName = "cat_spawn.wav"
    static let catAttackSoundName = "cat_attack.wav"
    static let cowSpawnSoundName = "cow_moo.wav"
    static let dangerSoundName = "danger_sting.wav"
    static let molotovGlassSoundName = "molotov_glass.wav"
    static let molotovExplosionSoundName = "molotov_explosion.wav"
    static let blockImpactSoundName = "block_impact.wav"
    static let parrySoundName = "parry_zoom.wav"

    static let obstacleRadius: CGFloat = 28
    static let destinationHeight: CGFloat = 96
    static let destinationTopInset: CGFloat = 140
    static let endingApproachDistance: CGFloat = 700
    static let endingPromptDistance: CGFloat = 350
    static let pizzaBonusDistanceBeforeDestination: CGFloat = 1_300

    static let routeColor = SKColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1)
    static let roadColor = SKColor(red: 0.22, green: 0.24, blue: 0.30, alpha: 1)
    static let frontageColor = SKColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1)
    static let sidewalkColor = SKColor(red: 0.25, green: 0.26, blue: 0.29, alpha: 1)
    static let playerColor = SKColor(red: 0.25, green: 0.85, blue: 0.95, alpha: 1)
    static let obstacleColor = SKColor(red: 0.95, green: 0.30, blue: 0.25, alpha: 1)
    static let destinationColor = SKColor(red: 0.35, green: 0.95, blue: 0.45, alpha: 1)
}
