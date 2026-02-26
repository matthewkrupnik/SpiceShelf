import XCTest
@testable import SpiceShelf

@MainActor
class PortionScalingTests: XCTestCase {

    // MARK: - canScale

    func testCanScaleWithValidServings() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [Ingredient(name: "Flour", quantity: 2, units: "cups")],
                            instructions: ["Mix"],
                            sourceURL: nil,
                            servings: 4)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        XCTAssertTrue(vm.canScale)
    }

    func testCanScaleWithNilServings() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [Ingredient(name: "Flour", quantity: 2, units: "cups")],
                            instructions: ["Mix"],
                            sourceURL: nil)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        XCTAssertFalse(vm.canScale)
    }

    func testCanScaleWithZeroServings() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [Ingredient(name: "Flour", quantity: 2, units: "cups")],
                            instructions: ["Mix"],
                            sourceURL: nil,
                            servings: 0)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        XCTAssertFalse(vm.canScale)
    }

    // MARK: - scaledIngredients

    func testScaleDoubleServings() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [
                                Ingredient(name: "Flour", quantity: 2, units: "cups"),
                                Ingredient(name: "Sugar", quantity: 1, units: "cup")
                            ],
                            instructions: ["Mix"],
                            sourceURL: nil,
                            servings: 4)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        vm.currentServings = 8

        let scaled = vm.scaledIngredients
        XCTAssertEqual(scaled.count, 2)
        XCTAssertEqual(scaled[0].quantity, 4.0, accuracy: 0.01)
        XCTAssertEqual(scaled[1].quantity, 2.0, accuracy: 0.01)
    }

    func testScaleHalfServings() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [
                                Ingredient(name: "Flour", quantity: 2, units: "cups"),
                                Ingredient(name: "Salt", quantity: 0.5, units: "tsp")
                            ],
                            instructions: ["Mix"],
                            sourceURL: nil,
                            servings: 4)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        vm.currentServings = 2

        let scaled = vm.scaledIngredients
        XCTAssertEqual(scaled[0].quantity, 1.0, accuracy: 0.01)
        XCTAssertEqual(scaled[1].quantity, 0.25, accuracy: 0.01)
    }

    func testScaleReturnOriginalWhenCurrentServingsNil() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [Ingredient(name: "Flour", quantity: 2, units: "cups")],
                            instructions: ["Mix"],
                            sourceURL: nil,
                            servings: 4)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        vm.currentServings = nil

        let scaled = vm.scaledIngredients
        XCTAssertEqual(scaled[0].quantity, 2.0, accuracy: 0.01)
    }

    func testScaleReturnOriginalWhenRecipeServingsNil() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [Ingredient(name: "Flour", quantity: 2, units: "cups")],
                            instructions: ["Mix"],
                            sourceURL: nil)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        vm.currentServings = 8

        let scaled = vm.scaledIngredients
        XCTAssertEqual(scaled[0].quantity, 2.0, accuracy: 0.01)
    }

    func testScaleSameServingsReturnsOriginalQuantities() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [Ingredient(name: "Flour", quantity: 2, units: "cups")],
                            instructions: ["Mix"],
                            sourceURL: nil,
                            servings: 4)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        vm.currentServings = 4

        let scaled = vm.scaledIngredients
        XCTAssertEqual(scaled[0].quantity, 2.0, accuracy: 0.01)
    }

    func testScaleTripleServings() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [Ingredient(name: "Eggs", quantity: 3, units: "")],
                            instructions: ["Beat"],
                            sourceURL: nil,
                            servings: 2)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        vm.currentServings = 6

        let scaled = vm.scaledIngredients
        XCTAssertEqual(scaled[0].quantity, 9.0, accuracy: 0.01)
    }

    func testInitialCurrentServingsMatchesRecipe() {
        let recipe = Recipe(id: UUID(),
                            title: "Test",
                            ingredients: [],
                            instructions: [],
                            sourceURL: nil,
                            servings: 6)
        let vm = RecipeDetailViewModel(recipe: recipe, cloudKitService: MockCloudKitService())
        XCTAssertEqual(vm.currentServings, 6)
    }
}
