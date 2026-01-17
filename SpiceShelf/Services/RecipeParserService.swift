import Foundation

enum RecipeParsingError: Error {
    case invalidData
    case parsingFailed
    case noRecipeFound
}

class RecipeParserService {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    func parseRecipe(from url: URL, completion: @escaping (Result<Recipe, Error>) -> Void) {
        let task = session.dataTask(with: url) { (data, _, error) in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { completion(.failure(RecipeParsingError.invalidData)) }
                return
            }

            // 1. Try JSON-LD parsing (Most reliable)
            if let recipe = self.extractJSONLDRecipe(from: htmlString, url: url) {
                DispatchQueue.main.async { completion(.success(recipe)) }
                return
            }

            // 2. Fallback: Try Meta Tags (OpenGraph)
            if let recipe = self.extractMetaTagRecipe(from: htmlString, url: url) {
                DispatchQueue.main.async { completion(.success(recipe)) }
                return
            }

            DispatchQueue.main.async { completion(.failure(RecipeParsingError.noRecipeFound)) }
        }
        task.resume()
    }

    private func extractJSONLDRecipe(from html: String, url: URL) -> Recipe? {
        let pattern = "<script type=\"application/ld\\+json\">(.*?)</script>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return nil }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard let range = Range(match.range(at: 1), in: html) else { continue }
            let jsonString = String(html[range])

            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) else { continue }

            // JSON-LD can be a dictionary or an array of dictionaries
            if let dict = json as? [String: Any], let recipe = parseJSONDict(dict, url: url) {
                return recipe
            } else if let array = json as? [[String: Any]] {
                for dict in array {
                    if let recipe = parseJSONDict(dict, url: url) {
                        return recipe
                    }
                }
            } else if let graphDict = json as? [String: Any], let graph = graphDict["@graph"] as? [[String: Any]] {
                 for dict in graph {
                    if let recipe = parseJSONDict(dict, url: url) {
                        return recipe
                    }
                }
            }
        }
        return nil
    }

    private func parseJSONDict(_ dict: [String: Any], url: URL) -> Recipe? {
        // Check for type "Recipe"
        guard let type = dict["@type"] as? String, type.contains("Recipe") else { return nil }

        let title = dict["name"] as? String ?? "Imported Recipe"
        let ingredients = parseIngredients(from: dict)
        let instructions = parseInstructions(from: dict)
        let servings = parseServings(from: dict)

        return Recipe(id: UUID(),
                      title: title,
                      ingredients: ingredients,
                      instructions: instructions,
                      sourceURL: url.absoluteString,
                      servings: servings,
                      imageAsset: nil)
    }

    private func parseIngredients(from dict: [String: Any]) -> [Ingredient] {
        guard let ingredientList = dict["recipeIngredient"] as? [String] else { return [] }
        return ingredientList.map { RecipeParserService.parseIngredientString($0) }
    }

    private func parseInstructions(from dict: [String: Any]) -> [String] {
        if let list = dict["recipeInstructions"] as? [[String: Any]] {
            return list.compactMap { $0["text"] as? String }
        } else if let list = dict["recipeInstructions"] as? [String] {
            return list
        } else if let str = dict["recipeInstructions"] as? String {
            return [str]
        }
        return []
    }

    private func parseServings(from dict: [String: Any]) -> Int {
        if let yield = dict["recipeYield"] as? String,
           let yieldInt = Int(yield.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            return yieldInt > 0 ? yieldInt : 4
        } else if let yieldInt = dict["recipeYield"] as? Int {
            return yieldInt
        }
        return 4
    }

    private func extractMetaTagRecipe(from html: String, url: URL) -> Recipe? {
        // Fallback title from OpenGraph
        let titlePattern = "<meta property=\"og:title\" content=\"(.*?)\""
        let title = extractMeta(pattern: titlePattern, from: html) ?? "Imported Recipe"

        // If we found nothing useful, fail
        if title == "Imported Recipe" { return nil }

        return Recipe(id: UUID(),
                      title: title,
                      ingredients: [],
                      instructions: [], // Cannot reliably extract without structured data
                      sourceURL: url.absoluteString,
                      servings: 4,
                      imageAsset: nil)
    }

    private func extractMeta(pattern: String, from html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else { return nil }
        guard let range = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[range])
    }

    static func parseIngredientString(_ raw: String) -> Ingredient {
         // Naive parser: "2 cups flour" -> 2.0, "cups", "flour"
         // This is very brittle but serves as a placeholder for NLP parsing
         let scanner = Scanner(string: raw)
         var quantity: Double = 0

         if let val = scanner.scanDouble() {
             quantity = val
         }

         let remainder = String(raw.dropFirst(scanner.currentIndex.utf16Offset(in: raw)))
            .trimmingCharacters(in: .whitespaces)
         // Split remaining by space to guess unit
         let parts = remainder.components(separatedBy: " ")
         if let unit = parts.first {
             let name = parts.dropFirst().joined(separator: " ")
             return Ingredient(id: UUID(),
                               name: name.isEmpty ? unit : name,
                               quantity: quantity,
                               units: name.isEmpty ? "" : unit)
         }

         return Ingredient(id: UUID(), name: raw, quantity: 0, units: "")
    }
}
