import XCTest
@testable import SpiceShelf

class IngredientParsingTests: XCTestCase {

    // MARK: - Basic Quantity + Unit + Name

    func testSimpleIngredient() {
        let result = RecipeParserService.parseIngredientString("2 cups flour")
        XCTAssertEqual(result.quantity, 2.0, accuracy: 0.01)
        XCTAssertEqual(result.units.lowercased(), "cups")
        XCTAssertTrue(result.name.lowercased().contains("flour"))
    }

    func testDecimalQuantity() {
        let result = RecipeParserService.parseIngredientString("1.5 tsp salt")
        XCTAssertEqual(result.quantity, 1.5, accuracy: 0.01)
        XCTAssertEqual(result.units.lowercased(), "tsp")
        XCTAssertTrue(result.name.lowercased().contains("salt"))
    }

    // MARK: - Fractions

    func testUnicodeFraction() {
        let result = RecipeParserService.parseIngredientString("½ cup sugar")
        XCTAssertEqual(result.quantity, 0.5, accuracy: 0.01)
        XCTAssertEqual(result.units.lowercased(), "cup")
        XCTAssertTrue(result.name.lowercased().contains("sugar"))
    }

    func testMixedNumberWithUnicodeFraction() {
        let result = RecipeParserService.parseIngredientString("1½ cups milk")
        XCTAssertEqual(result.quantity, 1.5, accuracy: 0.01)
    }

    func testTextFraction() {
        let result = RecipeParserService.parseIngredientString("1/2 cup butter")
        XCTAssertEqual(result.quantity, 0.5, accuracy: 0.01)
        XCTAssertTrue(result.name.lowercased().contains("butter"))
    }

    func testMixedNumberWithTextFraction() {
        let result = RecipeParserService.parseIngredientString("1 1/2 cups flour")
        XCTAssertEqual(result.quantity, 1.5, accuracy: 0.01)
    }

    // MARK: - Edge Cases

    func testNoQuantity() {
        let result = RecipeParserService.parseIngredientString("salt to taste")
        XCTAssertEqual(result.quantity, 0.0, accuracy: 0.01)
        XCTAssertFalse(result.name.isEmpty)
    }

    func testNoUnits() {
        let result = RecipeParserService.parseIngredientString("3 eggs")
        XCTAssertEqual(result.quantity, 3.0, accuracy: 0.01)
        XCTAssertTrue(result.name.lowercased().contains("egg"))
    }

    func testWhitespaceHandling() {
        let result = RecipeParserService.parseIngredientString("  2   cups   flour  ")
        XCTAssertEqual(result.quantity, 2.0, accuracy: 0.01)
        XCTAssertFalse(result.name.isEmpty)
    }

    func testEmptyString() {
        let result = RecipeParserService.parseIngredientString("")
        XCTAssertTrue(result.name.isEmpty || result.quantity == 0)
    }

    // MARK: - Various Units

    func testTablespoonUnit() {
        let result = RecipeParserService.parseIngredientString("2 tbsp olive oil")
        XCTAssertEqual(result.quantity, 2.0, accuracy: 0.01)
        XCTAssertEqual(result.units.lowercased(), "tbsp")
    }

    func testOunceUnit() {
        let result = RecipeParserService.parseIngredientString("8 oz cream cheese")
        XCTAssertEqual(result.quantity, 8.0, accuracy: 0.01)
        XCTAssertEqual(result.units.lowercased(), "oz")
    }

    func testGramUnit() {
        let result = RecipeParserService.parseIngredientString("250 g pasta")
        XCTAssertEqual(result.quantity, 250.0, accuracy: 0.01)
        XCTAssertEqual(result.units.lowercased(), "g")
    }

    func testQuarterFraction() {
        let result = RecipeParserService.parseIngredientString("¼ tsp pepper")
        XCTAssertEqual(result.quantity, 0.25, accuracy: 0.01)
    }

    func testThreeQuartersFraction() {
        let result = RecipeParserService.parseIngredientString("¾ cup rice")
        XCTAssertEqual(result.quantity, 0.75, accuracy: 0.01)
    }
}
