import XCTest

class ImportRecipeTests: XCTestCase {

    func testImportRecipeFlow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestUseMockCloudKit"]
        app.launch()

        // Tap the import button
        app.navigationBars["Spice Nook"].buttons["Import Recipe"].tap()

        // Enter a URL
        let urlTextField = app.textFields["Enter URL"]
        XCTAssertTrue(urlTextField.exists)
        urlTextField.tap()
        urlTextField.typeText("https://www.example.com")

        // Tap the import button
        app.buttons["Import"].tap()

        // The import will fail because example.com has no recipe data.
        // Verify the error alert appears and dismiss it.
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 10))
        errorAlert.buttons["OK"].tap()

        // Dismiss the sheet
        app.buttons["Cancel"].tap()

        // Verify the sheet is dismissed
        XCTAssertFalse(app.buttons["Import"].exists)
    }
}
