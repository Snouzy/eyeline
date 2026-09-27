import XCTest

// XCTestCase initializers are nonisolated, so the class cannot take the module default (MainActor).
nonisolated final class FlowTests: XCTestCase {
    @MainActor
    func testWriteReadPauseAndSetUp() {
        let app = launchInLandscape()
        openPrompter(in: app, text: "Salut, on regarde comment lire un script sans que cela se voie a la camera.")

        let centre = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centre.tap()
        // Each digit shows for one second, so the test accepts any of them.
        let digit = app.staticTexts.matching(NSPredicate(format: "label IN {'3', '2', '1'}")).firstMatch
        XCTAssertTrue(digit.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Réglages"].exists)

        sleep(4)
        XCTAssertFalse(digit.exists)
        centre.tap()
        XCTAssertTrue(app.buttons["Réglages"].waitForExistence(timeout: 2))

        app.buttons["Réglages"].tap()
        XCTAssertTrue(app.buttons["OK"].waitForExistence(timeout: 2))
        app.buttons["OK"].tap()

        app.buttons["Fermer"].tap()
        XCTAssertTrue(app.buttons["Lire"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTextPositionInPortrait() {
        let app = launchInLandscape()
        openPrompter(in: app, text: "Le texte passe sous la Pocket quand le telephone est debout.")

        XCUIDevice.shared.orientation = .portrait
        // On iOS 18, a tap during the rotation animation is lost.
        sleep(1)
        app.buttons["Réglages"].tap()
        XCTAssertTrue(app.buttons["OK"].waitForExistence(timeout: 2))
        // The menu label also holds the current choice: "Position du texte, En haut".
        let menu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Position du texte'")).firstMatch
        menu.tap()
        app.buttons["En bas"].tap()
        XCTAssertEqual(menu.label, "Position du texte, En bas")
        app.buttons["OK"].tap()

        app.buttons["Fermer"].tap()
        XCTAssertTrue(app.buttons["Lire"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLeavingAnEmptyScriptDeletesIt() {
        let app = launchInLandscape()
        let before = app.cells.count

        app.buttons["Nouveau script"].tap()
        XCTAssertTrue(app.textViews.firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.buttons["Nouveau script"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.cells.count, before)
    }

    @MainActor
    private func openPrompter(in app: XCUIApplication, text: String) {
        app.buttons["Nouveau script"].tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        // editor.tap() aims at the accessibility point of the text view, which is under the navigation bar.
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        editor.typeText(text)
        app.buttons["Lire"].tap()
        XCTAssertTrue(app.buttons["Réglages"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
    }

    // A test that ran in portrait leaves the device in portrait: each test sets the orientation it needs.
    @MainActor
    private func launchInLandscape() -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
        return app
    }
}
