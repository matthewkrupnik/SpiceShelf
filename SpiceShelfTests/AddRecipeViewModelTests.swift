import XCTest
import Combine
@testable import SpiceShelf

@MainActor
class AddRecipeViewModelTests: XCTestCase {

    func testSaveRecipe() async {
        // Given
        let mockCloudKitService = MockCloudKitService()
        let viewModel = AddRecipeViewModel(cloudKitService: mockCloudKitService)
        let expectation = self.expectation(description: "Save recipe expectation")
        mockCloudKitService.expectation = expectation

        // When
        let ingredients = [
            Ingredient(id: UUID(), name: "Ingredient 1", quantity: 1, units: "cup"),
            Ingredient(id: UUID(), name: "Ingredient 2", quantity: 2, units: "tbsp")
        ]
        let instructionSteps = [HowToStep("Step 1"), HowToStep("Step 2")]
        viewModel.saveRecipe(title: "Test Recipe",
                             ingredients: ingredients,
                             instructionSteps: instructionSteps)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(mockCloudKitService.saveRecipeCalled)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.title, "Test Recipe")
        XCTAssertEqual(mockCloudKitService.recipeSaved?.ingredients.count, 2)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.instructions.count, 2)
    }

    func testSaveRecipeWithNotes() async {
        // Given
        let mockCloudKitService = MockCloudKitService()
        let viewModel = AddRecipeViewModel(cloudKitService: mockCloudKitService)
        let expectation = self.expectation(description: "Save recipe with notes")
        mockCloudKitService.expectation = expectation

        // When
        viewModel.saveRecipe(title: "Recipe With Notes",
                             ingredients: [],
                             instructionSteps: [HowToStep("Step")],
                             notes: "Test note")

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockCloudKitService.recipeSaved?.notes, "Test note")
    }

    // MARK: - Failure Path Tests

    func testSaveRecipeEmptyTitleSetsValidationError() async {
        let mockCloudKitService = MockCloudKitService()
        let viewModel = AddRecipeViewModel(cloudKitService: mockCloudKitService)

        viewModel.saveRecipe(title: "  ",
                             ingredients: [Ingredient(id: UUID(), name: "Flour", quantity: 1, units: "cup")],
                             instructionSteps: [HowToStep("Mix")])

        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(mockCloudKitService.saveRecipeCalled)
        XCTAssertNil(viewModel.savedRecipe)
    }

    func testSaveRecipeSetsErrorOnCloudKitFailure() async {
        let mockCloudKitService = MockCloudKitService()
        mockCloudKitService.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        let viewModel = AddRecipeViewModel(cloudKitService: mockCloudKitService)

        let expectation = XCTestExpectation(description: "Save fails with error")
        let cancellable = viewModel.$error.dropFirst().sink { error in
            if error != nil { expectation.fulfill() }
        }

        viewModel.saveRecipe(title: "Test Recipe",
                             ingredients: [Ingredient(id: UUID(), name: "Flour", quantity: 1, units: "cup")],
                             instructionSteps: [HowToStep("Mix")])

        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertNotNil(viewModel.error)
        XCTAssertNil(viewModel.savedRecipe)
        cancellable.cancel()
    }
}