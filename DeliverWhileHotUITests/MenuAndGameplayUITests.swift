import XCTest

@MainActor
final class MenuAndGameplayUITests: XCTestCase {
    func testMenuInformationAndStartGame() {
        let app = XCUIApplication()
        app.launch()

        let howToPlay = app.buttons["menu.howToPlay"]
        XCTAssertTrue(howToPlay.waitForExistence(timeout: 5))
        howToPlay.tap()
        XCTAssertTrue(app.staticTexts["howToPlay.actions"].waitForExistence(timeout: 2))
        app.buttons["common.done"].tap()

        let about = app.buttons["menu.about"]
        XCTAssertTrue(about.exists)
        about.tap()
        XCTAssertTrue(app.staticTexts["about.description"].waitForExistence(timeout: 2))
        app.buttons["about.credits"].tap()
        XCTAssertTrue(app.staticTexts["about.creditsTitle"].waitForExistence(timeout: 2))
        app.buttons["credits.close"].tap()
        app.buttons["common.done"].tap()

        app.buttons["menu.newGame"].tap()
        XCTAssertTrue(app.buttons["controls.block"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["controls.joystick"].exists)
    }

    func testPauseResumeAndReturnConfirmation() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["menu.newGame"].tap()
        XCTAssertTrue(app.buttons["game.pause"].waitForExistence(timeout: 5))

        app.buttons["game.pause"].tap()
        XCTAssertTrue(app.buttons["pause.resume"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["pause.mainMenu"].exists)

        app.buttons["pause.mainMenu"].tap()
        XCTAssertTrue(app.buttons["pause.cancel"].waitForExistence(timeout: 2))

        app.buttons["pause.cancel"].tap()
        XCTAssertTrue(app.buttons["pause.resume"].waitForExistence(timeout: 2))

        app.buttons["pause.resume"].tap()
        XCTAssertTrue(app.buttons["game.pause"].waitForExistence(timeout: 2))

        app.buttons["game.pause"].tap()
        app.buttons["pause.mainMenu"].tap()
        app.buttons["pause.confirmLeave"].tap()
        XCTAssertTrue(app.buttons["menu.newGame"].waitForExistence(timeout: 3))
    }
}
