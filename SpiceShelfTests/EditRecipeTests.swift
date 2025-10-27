import XCTest
@testable import SpiceShelf

class EditRecipeTests: XCTestCase {

    func testUpdateRecipe() {
        print("Running testUpdateRecipe")
        // Given
        let recipe = Recipe(id: UUID(), title: "Original Title", ingredients: ["Original Ingredient"], instructions: ["Original Instruction"], sourceURL: nil)
        let mockCloudKitService = MockCloudKitService()
        let viewModel = RecipeDetailViewModel(recipe: recipe, cloudKitService: mockCloudKitService)
        
        // When
        viewModel.recipe.title = "Updated Title"
        viewModel.updateRecipe()
        
        // Then
        XCTAssertTrue(mockCloudKitService.updateRecipeCalled)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.title, "Updated Title")
    }

}
