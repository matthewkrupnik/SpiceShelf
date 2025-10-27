
import XCTest
@testable import SpiceShelf

class DeleteRecipeTests: XCTestCase {

    var viewModel: RecipeDetailViewModel!
    var mockCloudKitService: MockCloudKitService!

    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        let recipe = Recipe(id: UUID(), title: "Test Recipe", ingredients: ["Ingredient 1"], instructions: ["Instruction 1"], sourceURL: nil)
        viewModel = RecipeDetailViewModel(recipe: recipe, cloudKitService: mockCloudKitService)
    }

    override func tearDown() {
        viewModel = nil
        mockCloudKitService = nil
        super.tearDown()
    }

    func testDeleteRecipe() {
        let expectation = self.expectation(description: "Delete recipe expectation")
        
        viewModel.deleteRecipe()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertTrue(self.mockCloudKitService.deleteRecipeCalled)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
