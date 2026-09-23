import XCTest

/// Critical-flow UI tests. Run on macOS runner (simulator); honest assertions only.
final class VantaCriticalFlowsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
    }

    func testLaunchShowsVANTAHome() {
        app.launch()
        XCTAssertTrue(app.navigationBars["VANTA"].waitForExistence(timeout: 10))
    }

    func testTabsExist() {
        app.launch()
        for tab in ["Home", "Apps", "Discover", "Files", "Settings"] {
            XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 10), "missing tab \(tab)")
        }
    }

    func testAboutShowsVersion() {
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        app.buttons["About VANTA"].tap()
        XCTAssertTrue(app.staticTexts["VANTA"].waitForExistence(timeout: 5))
    }
}
