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

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button did not appear in alert")
        deleteButton.tap()

        XCTAssertFalse(recipeCell.waitForExistence(timeout: 5), "Recipe was not deleted.")
    }
}
