
import XCTest

class DeleteRecipeTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func testDeleteRecipe() throws {
        let app = XCUIApplication()
        app.collectionViews.cells.firstMatch.tap()
        
        app.buttons["Delete"].tap()
        
        // Add a delay to allow the UI to update
        let expectation = XCTestExpectation(description: "Wait for recipe to be deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertFalse(app.collectionViews.cells.firstMatch.exists)
    }
}
