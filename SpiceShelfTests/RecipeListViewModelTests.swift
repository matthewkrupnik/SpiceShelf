import XCTest
@testable import SpiceShelf

class RecipeListViewModelTests: XCTestCase {

    func testFetchRecipes() {
        print("Running testFetchRecipes")
        // Given
        let mockCloudKitService = MockCloudKitService()
        let viewModel = RecipeListViewModel(cloudKitService: mockCloudKitService)
        let expectation = XCTestExpectation(description: "Fetch recipes")
        
        // When
        let recipe = Recipe(id: UUID(), title: "Test Recipe", ingredients: ["Ingredient 1"], instructions: ["Step 1"], sourceURL: nil)
        mockCloudKitService.saveRecipe(recipe) { _ in }
        viewModel.fetchRecipes()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("Recipes count: \(viewModel.recipes.count)")
            XCTAssertFalse(viewModel.recipes.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }

}
