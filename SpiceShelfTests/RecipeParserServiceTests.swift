import XCTest
@testable import SpiceShelf

class RecipeParserServiceTests: XCTestCase {
    
    // Keep a strong reference to prevent premature deallocation during async operations
    var service: RecipeParserService?

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testParseRecipe() throws {
        service = RecipeParserService()
        let url = URL(string: "https://www.example.com")!

        let expectation = self.expectation(description: "Parsing completes")

        service?.parseRecipe(from: url) { result in
            switch result {
            case .success(let recipe):
                XCTAssertEqual(recipe.title, "Dummy Recipe")
                XCTAssertEqual(recipe.ingredients.map { $0.name }, ["Ingredient 1", "Ingredient 2"])
                XCTAssertEqual(recipe.instructions, ["Step 1", "Step 2"])
                XCTAssertEqual(recipe.sourceURL, url.absoluteString)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Parsing failed with error: \(error)")
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
