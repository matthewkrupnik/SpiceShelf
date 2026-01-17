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

        // --- Ingredients ---
        let smartField = app.textFields["SmartIngredientField"]
        XCTAssertTrue(smartField.waitForExistence(timeout: 2), "Smart ingredient field did not appear")
        
        smartField.tap()
        smartField.typeText("1 cup Ingredient 1")
        
        let addIngredientButton = app.buttons["AddIngredientButton"]
        addIngredientButton.tap()
        
        smartField.tap()
        smartField.typeText("2 tbsp Ingredient 2")
        addIngredientButton.tap()

        // --- Instructions ---
        let instructionStep1 = app.textFields["Step 1"]
        XCTAssertTrue(instructionStep1.waitForExistence(timeout: 2), "First instruction step field did not appear")
        instructionStep1.tap()
        instructionStep1.typeText("Step 1")

        app.buttons["Add Instruction"].tap()

        let instructionStep2 = app.textFields["Step 2"]
        XCTAssertTrue(instructionStep2.waitForExistence(timeout: 2), "Second instruction step field did not appear")
        instructionStep2.tap()
        instructionStep2.typeText("Step 2")

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
