import XCTest
@testable import SpiceShelf

@MainActor
class EditRecipeTests: XCTestCase {
    
    // Keep a strong reference to prevent premature deallocation during async operations
    var viewModel: RecipeDetailViewModel?

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testUpdateRecipe() async {
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
        // Allow more time for async scheduling on busy machines
        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertTrue(mockCloudKitService.updateRecipeCalled)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.title, "Updated Title")
    }
}
