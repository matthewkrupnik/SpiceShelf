import XCTest
@testable import SpiceShelf

class DeleteRecipeTests: XCTestCase {
    
    // Keep a strong reference to prevent premature deallocation during async operations
    var viewModel: RecipeDetailViewModel?

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testDeleteRecipe() {
        // Given
        let mockCloudKitService = MockCloudKitService()
        let recipe = Recipe(id: UUID(),
                              title: "Test Recipe",
                              ingredients: ["Test Ingredient"],
                              instructions: ["Test Instruction"],
                              sourceURL: nil)
        viewModel = RecipeDetailViewModel(recipe: recipe, cloudKitService: mockCloudKitService)
        let expectation = self.expectation(description: "Delete recipe expectation")
        mockCloudKitService.expectation = expectation

        // When
        viewModel?.deleteRecipe()

        // Then
        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertTrue(mockCloudKitService.deleteRecipeCalled)
    }
}
