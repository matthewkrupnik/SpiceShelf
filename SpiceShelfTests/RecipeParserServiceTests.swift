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
        // Setup Mock Session
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        service = RecipeParserService(session: session)
        let url = URL(string: "https://www.example.com/recipe")!
        
        // Mock HTML Response with JSON-LD
        let html = """
        <html>
        <head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org/",
          "@type": "Recipe",
          "name": "Test Recipe",
          "recipeIngredient": ["1 cup Sugar", "2 tbsp Spice"],
          "recipeInstructions": ["Mix", "Bake"],
          "recipeYield": "4 servings"
        }
        </script>
        </head>
        <body></body>
        </html>
        """
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, html.data(using: .utf8)!)
        }

        let expectation = self.expectation(description: "Parsing completes")

        service?.parseRecipe(from: url) { result in
            switch result {
            case .success(let recipe):
                XCTAssertEqual(recipe.title, "Test Recipe")
                XCTAssertEqual(recipe.ingredients.count, 2)
                XCTAssertEqual(recipe.ingredients[0].name, "Sugar") // Naive parser logic: "1 cup Sugar" -> unit "cup", name "Sugar"
                XCTAssertEqual(recipe.instructions, ["Mix", "Bake"])
                XCTAssertEqual(recipe.servings, 4)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Parsing failed with error: \(error)")
            }
        }

        waitForExpectations(timeout: 2, handler: nil)
    }
}

// Basic Mock URLProtocol
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data?))?
    
    override class func canInit(with request: URLRequest) -> Bool { return true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }
        
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
