import XCTest

class RecipeViewTests: XCTestCase {

    func testViewRecipe() throws {
        let app = XCUIApplication()
        app.launch()

        // Assuming there is at least one recipe in the list
        let firstRecipe = app.tables.cells.firstMatch
        XCTAssertTrue(firstRecipe.waitForExistence(timeout: 5))
        
        firstRecipe.tap()
        
        // Assert that the detail view is displayed
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
    }
}
