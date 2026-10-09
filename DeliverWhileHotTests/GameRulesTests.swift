import XCTest
@testable import DeliverWhileHot

@MainActor
final class GameRulesTests: XCTestCase {
    func testTemperatureFallsOverTimeAndNeverBelowZero() {
        var state = GameState()

        GameRules.advanceTemperature(&state, by: 10)
        XCTAssertEqual(state.foodTemperature, 0.73, accuracy: 0.000_001)

        GameRules.advanceTemperature(&state, by: 100)
        XCTAssertEqual(state.foodTemperature, 0)
    }

    func testObstacleDamageCannotReduceHealthBelowZero() {
        var state = GameState(health: 1)

        GameRules.applyObstacleDamage(&state)
        GameRules.applyObstacleDamage(&state)

        XCTAssertEqual(state.health, 0)
    }

    func testBribeSpendsQuarterFoodOnlyWhenAffordable() {
        var state = GameState(foodRemaining: 0.25)
        XCTAssertTrue(GameRules.payOfficerBribe(&state))
        XCTAssertEqual(state.foodRemaining, 0, accuracy: 0.000_001)

        XCTAssertFalse(GameRules.payOfficerBribe(&state))
        XCTAssertEqual(state.foodRemaining, 0, accuracy: 0.000_001)
    }

    func testBlockedHitAndPidgeotEachRemoveQuarterFoodWithoutGoingNegative() {
        var state = GameState(foodRemaining: 0.5)

        GameRules.applyBlockedHitFoodLoss(&state)
        GameRules.applyPidgeotMess(&state)
        GameRules.applyPidgeotMess(&state)

        XCTAssertEqual(state.foodRemaining, 0, accuracy: 0.000_001)
    }

    func testPizzaStealBonusRestoresHalfSliceButCapsAtFullOrder() {
        var state = GameState(foodRemaining: 0.25)
        GameRules.applyPizzaStealBonus(&state)
        XCTAssertEqual(state.foodRemaining, 0.75, accuracy: 0.000_001)

        GameRules.applyPizzaStealBonus(&state)
        XCTAssertEqual(state.foodRemaining, 1, accuracy: 0.000_001)
    }

    func testEatingUsesQuarterFoodToRestoreOneMissingHeart() {
        var state = GameState(health: 2, foodRemaining: 0.5)

        XCTAssertTrue(GameRules.consumeFood(&state))
        XCTAssertEqual(state.health, 3)
        XCTAssertEqual(state.foodRemaining, 0.25, accuracy: 0.000_001)
    }

    func testEatingDoesNothingWhenHealthyOrFoodIsInsufficient() {
        var healthy = GameState()
        XCTAssertFalse(GameRules.consumeFood(&healthy))
        XCTAssertEqual(healthy, GameState())

        var hungry = GameState(health: 2, foodRemaining: 0.24)
        XCTAssertFalse(GameRules.consumeFood(&hungry))
        XCTAssertEqual(hungry.health, 2)
        XCTAssertEqual(hungry.foodRemaining, 0.24, accuracy: 0.000_001)
    }

    func testDeliveryRequiresSurvivingHealthWarmFoodAndMinimumFood() {
        XCTAssertEqual(GameRules.deliveryResult(for: GameState()), .delivered)
        XCTAssertEqual(GameRules.deliveryResult(for: GameState(health: 0)), .healthDepleted)
        XCTAssertEqual(GameRules.deliveryResult(for: GameState(foodTemperature: 0.19)), .foodTooCold)
        XCTAssertEqual(GameRules.deliveryResult(for: GameState(foodRemaining: 0.24)), .insufficientFood)
    }
}
