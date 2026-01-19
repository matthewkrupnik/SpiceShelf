import XCTest
@testable import SpiceShelf

@MainActor
class DeleteRecipeTests: XCTestCase {
    
    // Keep a strong reference to prevent premature deallocation during async operations
    var viewModel: RecipeDetailViewModel?

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testDeleteRecipe() async {
        // Given
        let mockCloudKitService = MockCloudKitService()
        let recipe = Recipe(id: UUID(),
                              title: "Test Recipe",
                              ingredients: [Ingredient(id: UUID(), name: "Test Ingredient", quantity: 1.0, units: "")],
                              instructions: ["Test Instruction"],
                              sourceURL: nil)
        viewModel = RecipeDetailViewModel(recipe: recipe, cloudKitService: mockCloudKitService)
        let expectation = self.expectation(description: "Delete recipe expectation")
        mockCloudKitService.expectation = expectation

        // When
        viewModel?.deleteRecipe()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertTrue(mockCloudKitService.deleteRecipeCalled)
    }
}
