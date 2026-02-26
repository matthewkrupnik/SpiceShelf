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

    func testImportRecipePostsNotification() {
        let url = "https://www.example.com"
        viewModel.url = url
        
        let notificationExpectation = XCTNSNotificationExpectation(name: .recipeSaved)
        
        viewModel.importRecipe()
        
        wait(for: [notificationExpectation], timeout: 2.0)
    }

    // MARK: - Failure Path Tests

    func testImportRecipeBadURLSetsError() {
        viewModel.url = "not a valid url %%%"

        viewModel.importRecipe()

        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.state, .error)
        XCTAssertFalse(mockRecipeParserService.parseRecipeCalled)
    }

    func testImportRecipeParserFailureSetsError() async {
        mockRecipeParserService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Parse failed"])
        viewModel.url = "https://www.example.com"

        let expectation = XCTestExpectation(description: "Import fails with parser error")
        let cancellable = viewModel.$state.dropFirst().sink { state in
            if state == .error { expectation.fulfill() }
        }

        viewModel.importRecipe()

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.state, .error)
        XCTAssertTrue(mockRecipeParserService.parseRecipeCalled)
        XCTAssertFalse(mockCloudKitService.saveRecipeCalled)
        cancellable.cancel()
    }

    func testImportRecipeCloudKitFailureSetsError() async {
        mockCloudKitService.errorToThrow = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        viewModel.url = "https://www.example.com"

        let expectation = XCTestExpectation(description: "Import fails with CloudKit error")
        let cancellable = viewModel.$state.dropFirst().sink { state in
            if state == .error { expectation.fulfill() }
        }

        viewModel.importRecipe()

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.state, .error)
        XCTAssertTrue(mockRecipeParserService.parseRecipeCalled)
        XCTAssertTrue(mockCloudKitService.saveRecipeCalled)
        cancellable.cancel()
    }
}
