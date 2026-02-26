import XCTest
import Combine
@testable import SpiceShelf

@MainActor
class EditRecipeTests: XCTestCase {
    
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
        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertTrue(mockCloudKitService.updateRecipeCalled)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.title, "Updated Title")
    }

    // MARK: - Failure Path Tests

    func testSaveChangesSetsErrorOnFailure() async {
        let mockCloudKitService = MockCloudKitService()
        mockCloudKitService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [],
                            instructions: [],
                            sourceURL: nil)
        viewModel = RecipeDetailViewModel(recipe: recipe, cloudKitService: mockCloudKitService)

        let expectation = XCTestExpectation(description: "Save changes fails with error")
        let cancellable = viewModel!.$error.dropFirst().sink { error in
            if error != nil { expectation.fulfill() }
        }

        viewModel?.saveChanges()

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertNotNil(viewModel?.error)
        XCTAssertFalse(viewModel?.isLoading ?? true)
        cancellable.cancel()
    }
}
