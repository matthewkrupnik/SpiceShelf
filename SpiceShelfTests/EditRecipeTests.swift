import XCTest
@testable import SpiceShelf

class EditRecipeTests: XCTestCase {
    
    // Keep a strong reference to prevent premature deallocation during async operations
    var viewModel: RecipeDetailViewModel?

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testUpdateRecipe() {
        // Given
        let mockCloudKitService = MockCloudKitService()
        let recipe = Recipe(id: UUID(),
                              title: "Original Title",
                              ingredients: [Ingredient(id: UUID(), name: "Original Ingredient", quantity: 1.0, units: "")],
                              instructions: ["Original Instruction"],
                              sourceURL: nil)
        viewModel = RecipeDetailViewModel(recipe: recipe, cloudKitService: mockCloudKitService)
        let expectation = self.expectation(description: "Update recipe expectation")
        mockCloudKitService.expectation = expectation

        // When
        viewModel?.recipe.title = "Updated Title"
        viewModel?.saveChanges()

        // Then
        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertTrue(mockCloudKitService.updateRecipeCalled)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.title, "Updated Title")
    }
}
