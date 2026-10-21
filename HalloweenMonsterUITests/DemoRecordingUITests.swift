import XCTest

/// Drives the app through a short demo while CI records the simulator screen.
final class DemoRecordingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    func testSummonMonstersDemo() throws {
        waitForMonster()
        pause(2.5)

        let summon = app.buttons["summonButton"]
        for _ in 0..<3 {
            summon.tap()
            waitForMonster()
            pause(2.5)
        }

        app.buttons["favoriteButton"].tap()
        pause(1.5)

        // Switch to pictures searched from Wikimedia Commons.
        app.segmentedControls.buttons.element(boundBy: 1).tap()
        waitForMonster()
        pause(3)
        summon.tap()
        waitForMonster()
        pause(3)
        app.buttons["favoriteButton"].tap()
        pause(1.5)

        summon.tap()
        waitForMonster()
        pause(3)

        app.segmentedControls.buttons.element(boundBy: 0).tap()
        waitForMonster()
        pause(2.5)

        app.buttons["favoritesButton"].tap()
        XCTAssertTrue(app.staticTexts["我的怪物收藏"].waitForExistence(timeout: 10))
        pause(3.5)
        app.swipeDown(velocity: .fast)
        pause(2)

        let count = app.staticTexts["summonCount"].label
        XCTAssertFalse(count.contains(" 0 "), "Expected at least one monster to be summoned, got: \(count)")
    }

    private func waitForMonster(file: StaticString = #filePath, line: UInt = #line) {
        // Give the tap a moment to switch the card into its loading state.
        pause(0.4)
        let image = app.images["monsterImage"]
        XCTAssertTrue(image.waitForExistence(timeout: 45), "Monster picture never loaded", file: file, line: line)
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
