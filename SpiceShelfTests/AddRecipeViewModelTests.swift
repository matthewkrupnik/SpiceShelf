import XCTest
@testable import SpiceShelf

@MainActor
class AddRecipeViewModelTests: XCTestCase {

    func testSaveRecipe() async {
        print("Running testSaveRecipe")
        // Given
        let mockCloudKitService = MockCloudKitService()
        let viewModel = AddRecipeViewModel(cloudKitService: mockCloudKitService)
        let expectation = self.expectation(description: "Save recipe expectation")
        mockCloudKitService.expectation = expectation

        // When
        let ingredients = [
            Ingredient(id: UUID(), name: "Ingredient 1", quantity: 1, units: "cup"),
            Ingredient(id: UUID(), name: "Ingredient 2", quantity: 2, units: "tbsp")
        ]
        let instructions = ["Step 1", "Step 2"]
        viewModel.saveRecipe(title: "Test Recipe",
                             ingredients: ingredients,
                             instructions: instructions)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(mockCloudKitService.saveRecipeCalled)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.title, "Test Recipe")
        XCTAssertEqual(mockCloudKitService.recipeSaved?.ingredients.count, 2)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.instructions.count, 2)
    }

}