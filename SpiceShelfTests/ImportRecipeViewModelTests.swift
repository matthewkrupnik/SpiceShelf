
import XCTest
@testable import SpiceShelf

class ImportRecipeViewModelTests: XCTestCase {

    var viewModel: ImportRecipeViewModel!
    var mockCloudKitService: MockCloudKitService!
    var mockRecipeParserService: MockRecipeParserService!

    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        mockRecipeParserService = MockRecipeParserService()
        viewModel = ImportRecipeViewModel(cloudKitService: mockCloudKitService, recipeParserService: mockRecipeParserService)
    }

    override func tearDown() {
        viewModel = nil
        mockCloudKitService = nil
        mockRecipeParserService = nil
        super.tearDown()
    }

    func testImportRecipe() {
        let expectation = self.expectation(description: "Import recipe expectation")
        viewModel.urlString = "https://www.example.com/recipe"
        
        viewModel.importRecipe()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertTrue(self.mockRecipeParserService.parseRecipeCalled)
            XCTAssertTrue(self.mockCloudKitService.saveRecipeCalled)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}

class MockRecipeParserService: RecipeParserService {
    var parseRecipeCalled = false
    override func parseRecipe(from url: URL, completion: @escaping (Result<Recipe, Error>) -> Void) {
        parseRecipeCalled = true
        let recipe = Recipe(id: UUID(), title: "Parsed Recipe", ingredients: ["Parsed Ingredient"], instructions: ["Parsed Instruction"], sourceURL: url.absoluteString)
        completion(.success(recipe))
    }
}
