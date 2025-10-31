import XCTest

class DeleteRecipeTests: XCTestCase {

    func testDeleteRecipe() throws {
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
        let recipeTitle = "Recipe to be Deleted"
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

        // Now delete the recipe - wait for it to appear in the list
        let addedCell = app.staticTexts[recipeTitle]
        XCTAssertTrue(addedCell.waitForExistence(timeout: 5), "Added recipe cell did not appear")
        addedCell.tap()

        // Tap the trash icon in the navigation bar to show the delete confirmation
        let trashButton = app.buttons.matching(identifier: "trash").firstMatch
        XCTAssertTrue(trashButton.waitForExistence(timeout: 2), "Trash button did not appear")
        trashButton.tap()

        // Now tap the Delete button in the confirmation alert
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button did not appear in alert")
        deleteButton.tap()

        // After deletion, the recipe should not exist
        // Give a short moment for deletion to propagate
        let exists = addedCell.waitForExistence(timeout: 1)
        if exists {
            // if it still exists, allow a brief delay for UI update
            sleep(1)
        }
        XCTAssertFalse(app.tables.staticTexts[recipeTitle].exists)
    }
}
