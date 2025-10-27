import XCTest
@testable import SpiceShelf

class AddRecipeViewModelTests: XCTestCase {

    func testSaveRecipe() {
        print("Running testSaveRecipe")
        // Given
        let mockCloudKitService = MockCloudKitService()
        let viewModel = AddRecipeViewModel(cloudKitService: mockCloudKitService)
        
        // When
        // viewModel.saveRecipe(title: "Test Recipe", ingredients: "Ingredient 1\nIngredient 2", instructions: "Step 1\nStep 2")
        
        // Then
        XCTAssertTrue(mockCloudKitService.saveRecipeCalled)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.title, "Test Recipe")
    }

}