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

        // --- Ingredients --- (scroll down so the section is rendered)
        app.swipeUp()
        app.swipeUp()
        let qtyField = app.textFields["AddIngredientQty"]
        XCTAssertTrue(qtyField.waitForExistence(timeout: 3), "Quantity field did not appear")
        let nameField = app.textFields["SmartIngredientField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Ingredient name field did not appear")
        let addIngredientButton = app.buttons["AddIngredientButton"]

        qtyField.tap()
        qtyField.typeText("1")
        nameField.tap()
        nameField.typeText("Ingredient 1")
        addIngredientButton.tap()

        qtyField.tap()
        qtyField.typeText("2")
        nameField.tap()
        nameField.typeText("Ingredient 2")
        addIngredientButton.tap()

        // --- Instructions --- (scroll down so the section is rendered)
        app.swipeUp()
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
        
        // Assert the saved recipe appears in the recipe list
        let savedRecipe = app.staticTexts["Test Recipe"]
        XCTAssertTrue(savedRecipe.waitForExistence(timeout: 3), "Saved recipe did not appear in the list")
    }
}
