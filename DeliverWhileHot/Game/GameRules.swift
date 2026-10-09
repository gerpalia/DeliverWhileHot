//
//  GameRules.swift
//  DeliverWhileHot
//

struct GameRules {
    // Leave some warmth for the final approach; bonus pickups provide a safety margin
    // rather than being mandatory just to reach the destination.
    static let temperatureLossPerSecond = 0.027
    static let damagePerObstacleContact = 1
    static let foodCostPerMeal = 0.25
    static let bribeFoodCost = 0.25
    static let pidgeotFoodLoss = 0.25
    static let pizzaStealFoodAmount = 0.50
    static let blockedHitFoodLoss = 0.25
    static let healthRestoredPerMeal = 1
    static let minimumTemperatureForDelivery = 0.20
    static let minimumFoodForDelivery = 0.25

    static func advanceTemperature(_ state: inout GameState, by seconds: Double) {
        state.foodTemperature = max(0, state.foodTemperature - temperatureLossPerSecond * seconds)
    }

    static func applyObstacleDamage(_ state: inout GameState) {
        state.health = max(0, state.health - damagePerObstacleContact)
    }

    @discardableResult
    static func payOfficerBribe(_ state: inout GameState) -> Bool {
        guard state.foodRemaining >= bribeFoodCost else { return false }
        state.foodRemaining = max(0, state.foodRemaining - bribeFoodCost)
        return true
    }

    static func applyPidgeotMess(_ state: inout GameState) {
        state.foodRemaining = max(0, state.foodRemaining - pidgeotFoodLoss)
    }

    static func applyBlockedHitFoodLoss(_ state: inout GameState) {
        state.foodRemaining = max(0, state.foodRemaining - blockedHitFoodLoss)
    }

    static func applyPizzaStealBonus(_ state: inout GameState) {
        state.foodRemaining = min(GameState.startingFoodRemaining,
                                  state.foodRemaining + pizzaStealFoodAmount)
    }

    @discardableResult
    static func consumeFood(_ state: inout GameState) -> Bool {
        guard state.health < GameState.maximumHealth,
              state.foodRemaining >= foodCostPerMeal else { return false }

        state.health = min(GameState.maximumHealth,
                           state.health + healthRestoredPerMeal)
        state.foodRemaining = max(0, state.foodRemaining - foodCostPerMeal)
        return true
    }

    static func deliveryResult(for state: GameState) -> GameEndReason {
        if state.health <= 0 { return .healthDepleted }
        if state.foodTemperature < minimumTemperatureForDelivery { return .foodTooCold }
        if state.foodRemaining < minimumFoodForDelivery { return .insufficientFood }
        return .delivered
    }
}
