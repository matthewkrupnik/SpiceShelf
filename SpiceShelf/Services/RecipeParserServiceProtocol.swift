import Foundation

protocol RecipeParserServiceProtocol: Sendable {
    func parseRecipe(from url: URL) async throws -> Recipe
}
