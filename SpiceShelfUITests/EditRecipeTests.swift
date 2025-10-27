import XCTest

class EditRecipeTests: XCTestCase {

    func testEditRecipe() throws {
        let app = XCUIApplication()
        app.launch()

        // Assuming there is at least one recipe in the list
        let firstRecipe = app.tables.cells.firstMatch
        XCTAssertTrue(firstRecipe.waitForExistence(timeout: 5))
        
        firstRecipe.tap()
        
        app.buttons["Edit"].tap()
        
        let titleTextField = app.textFields["Title"]
        titleTextField.tap()
        titleTextField.typeText(" Updated")
        
        app.buttons["Save"].tap()
        
        // Assert that the title has been updated
        XCTAssertTrue(app.navigationBars.staticTexts["Original Title Updated"].waitForExistence(timeout: 5))
    }
}
