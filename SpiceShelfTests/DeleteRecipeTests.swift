import XCTest
import Combine
@testable import SpiceShelf

@MainActor
class DeleteRecipeTests: XCTestCase {
    
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

    // MARK: - Failure Path Tests

    func testDeleteRecipeSetsErrorOnFailure() async {
        let mockCloudKitService = MockCloudKitService()
        mockCloudKitService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        let recipe = Recipe(id: UUID(),
                            title: "Test Recipe",
                            ingredients: [],
                            instructions: [],
                            sourceURL: nil)
        viewModel = RecipeDetailViewModel(recipe: recipe, cloudKitService: mockCloudKitService)

        let expectation = XCTestExpectation(description: "Delete fails with error")
        let cancellable = viewModel!.$error.dropFirst().sink { error in
            if error != nil { expectation.fulfill() }
        }

        viewModel?.deleteRecipe()

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertNotNil(viewModel?.error)
        XCTAssertFalse(viewModel?.isLoading ?? true)
        XCTAssertFalse(viewModel?.isShowingDeleteConfirmation ?? true)
        cancellable.cancel()
    }
}
