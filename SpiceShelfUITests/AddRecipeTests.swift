import XCTest

class AddRecipeTests: XCTestCase {

    func testAddRecipe() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestUseMockCloudKit"]
        app.launch()
        
        // Wait for the Add Recipe button to appear
        let addButton = app.buttons["Add Recipe"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Recipe button did not appear")
        addButton.tap()

        let titleTextField = app.textFields["Title"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 2), "Title field did not appear")
        titleTextField.tap()
        titleTextField.typeText("Test Recipe")

        let ingredientsTextField = app.textFields["Ingredients"]
        XCTAssertTrue(ingredientsTextField.waitForExistence(timeout: 2), "Ingredients field did not appear")
        ingredientsTextField.tap()
        ingredientsTextField.typeText("Ingredient 1\nIngredient 2")

        let instructionsTextField = app.textFields["Instructions"]
        XCTAssertTrue(instructionsTextField.waitForExistence(timeout: 2), "Instructions field did not appear")
        instructionsTextField.tap()
        instructionsTextField.typeText("Step 1\nStep 2")

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button did not appear")
        saveButton.tap()

        // Wait for the Add Recipe sheet to dismiss
        XCTAssertFalse(titleTextField.waitForExistence(timeout: 3), "Add Recipe view did not dismiss")
        
        // Assert the saved recipe appears in the recipe list
        let savedRecipe = app.staticTexts["Test Recipe"]
        XCTAssertTrue(savedRecipe.waitForExistence(timeout: 3), "Saved recipe did not appear in the list")
    }
}
