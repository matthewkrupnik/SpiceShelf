import XCTest
import Combine
@testable import SpiceShelf

@MainActor
class RecipeListViewModelTests: XCTestCase {
    
    var viewModel: RecipeListViewModel?
    var mockCloudKitService: MockCloudKitService?

    override func tearDown() {
        viewModel = nil
        mockCloudKitService = nil
        super.tearDown()
    }

    func testFetchRecipes() async {
        // Given
        mockCloudKitService = MockCloudKitService()
        viewModel = RecipeListViewModel(cloudKitService: mockCloudKitService!)
        let expectation = XCTestExpectation(description: "Fetch recipes")

        let recipe = Recipe(id: UUID(),
                              title: "Test Recipe",
                              ingredients: [Ingredient(id: UUID(), name: "Ingredient 1", quantity: 1.0, units: "")],
                              instructions: ["Step 1"],
                              sourceURL: nil)
        _ = try? await mockCloudKitService?.saveRecipe(recipe)

        let cancellable = viewModel!.$state.sink { state in
            if state == .loaded {
                XCTAssertFalse(self.viewModel?.recipes.isEmpty ?? true)
                expectation.fulfill()
            }
        }

        viewModel?.fetchRecipes()

        await fulfillment(of: [expectation], timeout: 2)
        cancellable.cancel()
    }

    // MARK: - Failure Path Tests

    func testFetchRecipesSetsErrorOnFailure() async {
        mockCloudKitService = MockCloudKitService()
        mockCloudKitService!.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        viewModel = RecipeListViewModel(cloudKitService: mockCloudKitService!)

        let expectation = XCTestExpectation(description: "Fetch fails with error")
        let cancellable = viewModel!.$state.sink { state in
            if state == .error { expectation.fulfill() }
        }

        viewModel?.fetchRecipes()

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertNotNil(viewModel?.error)
        XCTAssertTrue(viewModel?.recipes.isEmpty ?? false)
        cancellable.cancel()
    }

    func testDeleteRecipeSetsErrorOnFailure() async {
        mockCloudKitService = MockCloudKitService()
        viewModel = RecipeListViewModel(cloudKitService: mockCloudKitService!)

        let recipe = Recipe(id: UUID(),
                            title: "Delete Me",
                            ingredients: [],
                            instructions: [],
                            sourceURL: nil)
        viewModel?.recipes = [recipe]
        mockCloudKitService!.errorToThrow = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])

        let expectation = XCTestExpectation(description: "Delete fails with error")
        let cancellable = viewModel!.$error.dropFirst().sink { error in
            if error != nil { expectation.fulfill() }
        }

        viewModel?.deleteRecipe(recipe)

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertNotNil(viewModel?.error)
        XCTAssertEqual(viewModel?.recipes.count, 1)
        cancellable.cancel()
    }
}
