import XCTest
@testable import SpiceShelf

class RecipeListViewModelTests: XCTestCase {
    
    // Keep a strong reference to prevent premature deallocation during async operations
    var viewModel: RecipeListViewModel?
    var mockCloudKitService: MockCloudKitService?

    override func tearDown() {
        viewModel = nil
        mockCloudKitService = nil
        super.tearDown()
    }

    func testFetchRecipes() {
        print("Running testFetchRecipes")
        // Given
        mockCloudKitService = MockCloudKitService()
        viewModel = RecipeListViewModel(cloudKitService: mockCloudKitService!)
        let expectation = XCTestExpectation(description: "Fetch recipes")

        // When
        let recipe = Recipe(id: UUID(),
                              title: "Test Recipe",
                              ingredients: [Ingredient(id: UUID(), name: "Ingredient 1", quantity: 1.0, units: "")],
                              instructions: ["Step 1"],
                              sourceURL: nil)
        mockCloudKitService?.saveRecipe(recipe) { _ in }
        viewModel?.fetchRecipes()

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("Recipes count: \(self.viewModel?.recipes.count ?? 0)")
            XCTAssertFalse(self.viewModel?.recipes.isEmpty ?? true)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

}
