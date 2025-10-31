import XCTest

class EditRecipeTests: XCTestCase {

    func testEditRecipe() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestUseMockCloudKit"]
        app.launch()

        // Wait for the Add Recipe button to appear
        let addButton = app.buttons["Add Recipe"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Recipe button did not appear")
        addButton.tap()

        let titleTextField = app.textFields["Title"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 2), "Title text field did not appear")
        titleTextField.tap()
        let recipeTitle = "Recipe to be Edited"
        titleTextField.typeText(recipeTitle)

        let ingredientsTextField = app.textFields["Ingredients"]
        XCTAssertTrue(ingredientsTextField.waitForExistence(timeout: 2), "Ingredients text field did not appear")
        ingredientsTextField.tap()
        ingredientsTextField.typeText("Ingredient 1")

        let instructionsTextField = app.textFields["Instructions"]
        XCTAssertTrue(instructionsTextField.waitForExistence(timeout: 2), "Instructions text field did not appear")
        instructionsTextField.tap()
        instructionsTextField.typeText("Step 1")

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button did not appear")
        saveButton.tap()
        
        // Wait for the Add Recipe sheet to dismiss
        XCTAssertFalse(titleTextField.waitForExistence(timeout: 3), "Add Recipe view did not dismiss")
        
        // Navigate to the recipe detail view by tapping the recipe in the list
        let recipeCell = app.staticTexts[recipeTitle]
        XCTAssertTrue(recipeCell.waitForExistence(timeout: 5), "Recipe cell did not appear in the list")
        recipeCell.tap()
        
        // Now tap the Edit button in the recipe detail view
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Edit button did not appear")
        editButton.tap()

        // Wait for the edit sheet to appear by checking for the Cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2), "Edit sheet did not appear")

        // Find the title text field in the edit view
        let editTitleTextField = app.textFields["Recipe Title"]
        XCTAssertTrue(editTitleTextField.waitForExistence(timeout: 2), "Edit title field did not appear")
        editTitleTextField.tap()
        
        // Clear the existing text
        guard let stringValue = editTitleTextField.value as? String else {
            XCTFail("Could not get string value of text field")
            return
        }

        // Select all and delete
        editTitleTextField.doubleTap()
        if app.menuItems["Select All"].exists {
            app.menuItems["Select All"].tap()
        }
        editTitleTextField.typeText("")
        
        // Type the new title
        editTitleTextField.typeText("Updated Recipe Title")

        // Save the changes
        let saveButtonInEdit = app.buttons["Save"]
        XCTAssertTrue(saveButtonInEdit.waitForExistence(timeout: 2), "Save button in edit view did not appear")
        saveButtonInEdit.tap()

        // Wait for edit sheet to dismiss
        XCTAssertFalse(cancelButton.waitForExistence(timeout: 3), "Edit sheet did not dismiss")

        // Give the view model time to save and update
        sleep(1)

        // Verify the updated title appears in the detail view
        // The title appears as a large title text in the detail view
        let updatedTitle = app.staticTexts["Recipe to be Updated Recipe Title"]
        XCTAssertTrue(updatedTitle.waitForExistence(timeout: 5), "Updated recipe title did not appear")
    }
}
