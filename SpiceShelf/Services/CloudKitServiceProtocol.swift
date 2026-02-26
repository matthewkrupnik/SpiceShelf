import Foundation

protocol CloudKitServiceProtocol: Sendable {
    func saveRecipe(_ recipe: Recipe) async throws -> Recipe
    func fetchRecipes() async throws -> [Recipe]
    func updateRecipe(_ recipe: Recipe) async throws -> Recipe
    func deleteRecipe(_ recipe: Recipe) async throws
}
