//
//  GameState.swift
//  DeliverWhileHot
//

struct GameState: Equatable {
    static let maximumHealth = 3
    static let startingHealth = 3
    static let startingTemperature = 1.0
    static let startingFoodRemaining = 1.0

    var health = Self.startingHealth
    var foodTemperature = Self.startingTemperature
    var foodRemaining = Self.startingFoodRemaining
    var phase: GamePhase = .playing
}

enum GamePhase: Equatable {
    case playing
    case ended(GameEndReason)
}

enum GameEndReason: Equatable {
    case delivered
    case healthDepleted
    case foodTooCold
    case insufficientFood
}
