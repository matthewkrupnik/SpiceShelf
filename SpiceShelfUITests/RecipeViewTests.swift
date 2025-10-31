import XCTest

class RecipeViewTests: XCTestCase {

    func testViewRecipe() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestUseMockCloudKit"]
        app.launch()

        // First, create a recipe to view
        let addButton = app.buttons["Add Recipe"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Recipe button did not appear")
        addButton.tap()

        let titleTextField = app.textFields["Title"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 2), "Title field did not appear")
        titleTextField.tap()
        let recipeTitle = "Test Recipe to View"
        titleTextField.typeText(recipeTitle)

        let ingredientsTextField = app.textFields["Ingredients"]
        XCTAssertTrue(ingredientsTextField.waitForExistence(timeout: 2), "Ingredients field did not appear")
        ingredientsTextField.tap()
        ingredientsTextField.typeText("Test Ingredient")

        let instructionsTextField = app.textFields["Instructions"]
        XCTAssertTrue(instructionsTextField.waitForExistence(timeout: 2), "Instructions field did not appear")
        instructionsTextField.tap()
        instructionsTextField.typeText("Test Instruction")

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button did not appear")
        saveButton.tap()

        // Wait for the Add Recipe sheet to dismiss
        XCTAssertFalse(titleTextField.waitForExistence(timeout: 3), "Add Recipe view did not dismiss")

        // Now view the recipe
        let recipeCell = app.staticTexts[recipeTitle]
        XCTAssertTrue(recipeCell.waitForExistence(timeout: 5), "Recipe cell did not appear in list")

        recipeCell.tap()

        // Assert that the detail view is displayed by checking for the recipe title
        let detailTitle = app.staticTexts[recipeTitle]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 5), "Recipe detail view did not appear")
        
        // Verify navigation bar exists
        XCTAssertTrue(app.navigationBars.element.exists, "Navigation bar did not appear")
    }
}
