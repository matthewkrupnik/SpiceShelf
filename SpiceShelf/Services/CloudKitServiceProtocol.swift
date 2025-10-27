import Foundation

protocol CloudKitServiceProtocol {
    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void)
    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void)
    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void)
    func deleteRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void)
}
