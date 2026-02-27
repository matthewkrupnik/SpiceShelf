import XCTest

class DeleteRecipeTests: XCTestCase {

    func testDeleteRecipe() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestUseMockCloudKit", "UITestWithMockRecipes"]
        app.launch()

        let recipeTitle = "Recipe to be Deleted"
        let recipeCell = app.staticTexts[recipeTitle]
        XCTAssertTrue(recipeCell.waitForExistence(timeout: 5), "Recipe to be deleted not found.")
        recipeCell.tap()

        let trashButton = app.buttons.matching(identifier: "trash").firstMatch
        XCTAssertTrue(trashButton.waitForExistence(timeout: 2), "Trash button did not appear")
        trashButton.tap()

        let alert = app.alerts["Delete Recipe"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2), "Delete confirmation alert did not appear")
        alert.buttons["Delete"].tap()

        XCTAssertFalse(recipeCell.waitForExistence(timeout: 5), "Recipe was not deleted.")
    }
}
