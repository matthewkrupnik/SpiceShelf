import XCTest

class ImportRecipeTests: XCTestCase {

    func testImportRecipeFlow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestUseMockCloudKit"]
        app.launch()

        // Tap the import button
        app.navigationBars["Recipes"].buttons["square.and.arrow.down"].tap()

        // Enter a URL
        let urlTextField = app.textFields["Enter URL"]
        XCTAssertTrue(urlTextField.exists)
        urlTextField.tap()
        urlTextField.typeText("https://www.example.com")

        // Tap the import button
        app.buttons["Import"].tap()

        // For now, we just check that the sheet is dismissed
        // In a real test, we would check if the new recipe appears in the list
        XCTAssertFalse(app.buttons["Import"].exists)
    }
}
