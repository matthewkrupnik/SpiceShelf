import XCTest

class AddRecipeTests: XCTestCase {

    func testAddRecipe() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Add Recipe"].tap()
        
        let titleTextField = app.textFields["Title"]
        titleTextField.tap()
        titleTextField.typeText("Test Recipe")
        
        let ingredientsTextField = app.textFields["Ingredients"]
        ingredientsTextField.tap()
        ingredientsTextField.typeText("Ingredient 1\nIngredient 2")
        
        let instructionsTextField = app.textFields["Instructions"]
        instructionsTextField.tap()
        instructionsTextField.typeText("Step 1\nStep 2")
        
        app.buttons["Save"].tap()
        
        // How to assert that the recipe was saved and appears in the recipe list?
        // I need to be able to access the recipe list view.
    }
}
