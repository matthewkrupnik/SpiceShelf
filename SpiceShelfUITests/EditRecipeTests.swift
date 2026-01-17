import XCTest

class EditRecipeTests: XCTestCase {

    func testEditRecipe() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestUseMockCloudKit", "UITestWithMockRecipes"]
        app.launch()

        let recipeTitle = "Recipe to be Edited"
        let recipeCell = app.staticTexts[recipeTitle]
        XCTAssertTrue(recipeCell.waitForExistence(timeout: 5), "Recipe to be edited not found.")
        recipeCell.tap()

        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Edit button did not appear")
        editButton.tap()

        let editTitleTextField = app.textFields["Recipe Title"]
        XCTAssertTrue(editTitleTextField.waitForExistence(timeout: 2), "Edit title field did not appear")
        editTitleTextField.tap()

        editTitleTextField.tap()
        // Clear the text field by typing backspaces
        let currentText = editTitleTextField.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count)
        editTitleTextField.typeText(deleteString)

        let updatedRecipeTitle = "Updated Recipe Title"
        editTitleTextField.typeText(updatedRecipeTitle)

        let saveButtonInEdit = app.buttons["Save"]
        XCTAssertTrue(saveButtonInEdit.waitForExistence(timeout: 2), "Save button in edit view did not appear")
        saveButtonInEdit.tap()

        let updatedTitle = app.staticTexts[updatedRecipeTitle]
        XCTAssertTrue(updatedTitle.waitForExistence(timeout: 5), "Updated recipe title did not appear")
    }
}
