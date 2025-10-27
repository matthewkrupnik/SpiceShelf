
import XCTest

class ImportRecipeTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func testImportRecipe() throws {
        let app = XCUIApplication()
        
        // Assuming there is a button to navigate to the import view
        app.buttons["Import"].tap()
        
        let urlTextField = app.textFields["URL"]
        urlTextField.tap()
        urlTextField.typeText("https://www.example.com/recipe")
        
        app.buttons["Import Recipe"].tap()
        
        // Add a delay to allow the UI to update
        let expectation = XCTestExpectation(description: "Wait for recipe to be imported")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertTrue(app.collectionViews.cells.staticTexts["Example Recipe"].exists)
    }
}
