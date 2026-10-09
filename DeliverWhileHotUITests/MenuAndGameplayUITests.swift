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
        XCTAssertTrue(app.staticTexts["about.title"].waitForExistence(timeout: 2))
        app.buttons["common.done"].tap()

        app.buttons["menu.newGame"].tap()
        XCTAssertTrue(app.buttons["controls.block"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["controls.joystick"].exists)
    }
}
