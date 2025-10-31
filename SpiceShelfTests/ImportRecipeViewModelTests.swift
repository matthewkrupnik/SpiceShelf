import XCTest
import Combine
@testable import SpiceShelf

@MainActor
class ImportRecipeViewModelTests: XCTestCase {

    var viewModel: ImportRecipeViewModel!
    var mockRecipeParserService: MockRecipeParserService!
    var mockCloudKitService: MockCloudKitService!

    override func setUpWithError() throws {
        mockRecipeParserService = MockRecipeParserService()
        mockCloudKitService = MockCloudKitService()
        viewModel = ImportRecipeViewModel(recipeParserService: mockRecipeParserService,
                                          cloudKitService: mockCloudKitService)
    }

    func testImportRecipe() throws {
        let url = "https://www.example.com"
        viewModel.url = url

        let expectation = self.expectation(description: "Import completes")

        // Observe the state of the view model
        let cancellable = viewModel.$state.sink { state in
            if state == .success {
                XCTAssertTrue(self.mockRecipeParserService.parseRecipeCalled)
                XCTAssertEqual(self.mockRecipeParserService.urlToParse, URL(string: url))
                XCTAssertTrue(self.mockCloudKitService.saveRecipeCalled)
                XCTAssertEqual(self.mockCloudKitService.recipeSaved?.title, "Dummy Recipe")
                expectation.fulfill()
            } else if state == .error {
                XCTFail("Import failed with error: \(String(describing: self.viewModel.error))")
            }
        }

        viewModel.importRecipe()

        waitForExpectations(timeout: 5, handler: nil)
        cancellable.cancel()
    }
}
