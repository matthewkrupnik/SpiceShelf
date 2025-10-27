
import XCTest
@testable import SpiceShelf

class RecipeParserServiceTests: XCTestCase {

    var recipeParserService: RecipeParserService!

    override func setUp() {
        super.setUp()
        recipeParserService = RecipeParserService()
    }

    override func tearDown() {
        recipeParserService = nil
        super.tearDown()
    }

    func testParseRecipe() {
        let expectation = self.expectation(description: "Parse recipe expectation")
        let url = URL(string: "https://www.example.com/recipe")!
        
        recipeParserService.parseRecipe(from: url) { result in
            switch result {
            case .success(let recipe):
                XCTAssertEqual(recipe.title, "Example Recipe")
                XCTAssertEqual(recipe.ingredients, ["Ingredient 1", "Ingredient 2"])
                XCTAssertEqual(recipe.instructions, ["Step 1", "Step 2"])
            case .failure(let error):
                XCTFail("Parsing failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
