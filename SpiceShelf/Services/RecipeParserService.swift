import Foundation

enum RecipeParsingError: Error, LocalizedError {
    case invalidData
    case parsingFailed
    case noRecipeFound
    case unsupportedSite
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Could not read the webpage data."
        case .parsingFailed:
            return "Failed to parse the recipe from the page."
        case .noRecipeFound:
            return "No recipe found on this page."
        case .unsupportedSite:
            return "This website is not supported for recipe import."
        }
    }
}

// MARK: - Site-Specific Parser Protocol

protocol SiteSpecificParser {
    static var supportedHosts: [String] { get }
    static func canParse(url: URL) -> Bool
    func parse(html: String, url: URL) -> Recipe?
}

extension SiteSpecificParser {
    static func canParse(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return supportedHosts.contains { host.contains($0) }
    }
}

// MARK: - Main Parser Service

class RecipeParserService {
    
    private let session: URLSession
    private let siteSpecificParsers: [SiteSpecificParser]
    
    init(session: URLSession = .shared) {
        self.session = session
        self.siteSpecificParsers = [
            AllRecipesParser(),
            SeriousEatsParser(),
            NYTCookingParser(),
            FoodNetworkParser(),
            SallysBakingParser(),
            RecipeTinEatsParser(),
            BudgetBytesParser(),
            TheKitchnParser(),
            SimplyRecipesParser(),
            EpicuriousParser(),
            SmittenKitchenParser(),
            LoveAndLemonsParser(),
            BBCGoodFoodParser(),
            DelishParser(),
            TasteOfHomeParser()
        ]
    }

    func parseRecipe(from url: URL, completion: @escaping (Result<Recipe, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { completion(.failure(RecipeParsingError.invalidData)) }
                return
            }

            // 1. Try site-specific parser first
            for parser in self.siteSpecificParsers {
                if type(of: parser).canParse(url: url) {
                    if let recipe = parser.parse(html: htmlString, url: url) {
                        DispatchQueue.main.async { completion(.success(recipe)) }
                        return
                    }
                }
            }

            // 2. Try generic JSON-LD parsing
            if let recipe = self.extractJSONLDRecipe(from: htmlString, url: url) {
                DispatchQueue.main.async { completion(.success(recipe)) }
                return
            }

            // 3. Try Microdata parsing
            if let recipe = self.extractMicrodataRecipe(from: htmlString, url: url) {
                DispatchQueue.main.async { completion(.success(recipe)) }
                return
            }

            // 4. Fallback: Try Meta Tags (OpenGraph)
            if let recipe = self.extractMetaTagRecipe(from: htmlString, url: url) {
                DispatchQueue.main.async { completion(.success(recipe)) }
                return
            }

            DispatchQueue.main.async { completion(.failure(RecipeParsingError.noRecipeFound)) }
        }
        task.resume()
    }

    // MARK: - JSON-LD Parsing
    
    func extractJSONLDRecipe(from html: String, url: URL) -> Recipe? {
        let pattern = "<script type=\"application/ld\\+json\"[^>]*>(.*?)</script>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { return nil }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard let range = Range(match.range(at: 1), in: html) else { continue }
            var jsonString = String(html[range])
            
            // Clean up common issues in JSON-LD
            jsonString = cleanJSONString(jsonString)

            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData, options: [.fragmentsAllowed]) else { continue }

            if let recipe = findRecipeInJSON(json, url: url) {
                return recipe
            }
        }
        return nil
    }
    
    private func cleanJSONString(_ jsonString: String) -> String {
        var cleaned = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove HTML comments that sometimes appear
        if let commentRegex = try? NSRegularExpression(pattern: "<!--.*?-->", options: .dotMatchesLineSeparators) {
            cleaned = commentRegex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
        }
        
        // Handle escaped characters
        cleaned = cleaned
            .replacingOccurrences(of: "\\/", with: "/")
        
        return cleaned
    }
    
    private func findRecipeInJSON(_ json: Any, url: URL) -> Recipe? {
        // Direct dictionary
        if let dict = json as? [String: Any] {
            if let recipe = parseJSONDict(dict, url: url) {
                return recipe
            }
            // Check @graph array
            if let graph = dict["@graph"] as? [[String: Any]] {
                for item in graph {
                    if let recipe = parseJSONDict(item, url: url) {
                        return recipe
                    }
                }
            }
        }
        
        // Array of dictionaries
        if let array = json as? [[String: Any]] {
            for dict in array {
                if let recipe = parseJSONDict(dict, url: url) {
                    return recipe
                }
            }
        }
        
        // Array containing mixed types
        if let array = json as? [Any] {
            for item in array {
                if let dict = item as? [String: Any], let recipe = parseJSONDict(dict, url: url) {
                    return recipe
                }
            }
        }
        
        return nil
    }

    func parseJSONDict(_ dict: [String: Any], url: URL) -> Recipe? {
        // Check for type "Recipe" - can be string or array
        let isRecipe: Bool
        if let type = dict["@type"] as? String {
            isRecipe = type.lowercased().contains("recipe")
        } else if let types = dict["@type"] as? [String] {
            isRecipe = types.contains { $0.lowercased().contains("recipe") }
        } else {
            isRecipe = false
        }
        
        guard isRecipe else { return nil }

        let title = extractTitle(from: dict)
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
    
    private func extractTitle(from dict: [String: Any]) -> String {
        if let name = dict["name"] as? String, !name.isEmpty {
            return decodeHTMLEntities(name)
        }
        if let headline = dict["headline"] as? String, !headline.isEmpty {
            return decodeHTMLEntities(headline)
        }
        return "Imported Recipe"
    }

    func parseIngredients(from dict: [String: Any]) -> [Ingredient] {
        guard let ingredientList = dict["recipeIngredient"] as? [String] else { return [] }
        return ingredientList.map { RecipeParserService.parseIngredientString(decodeHTMLEntities($0)) }
    }

    func parseInstructions(from dict: [String: Any]) -> [String] {
        // Handle HowToStep objects
        if let list = dict["recipeInstructions"] as? [[String: Any]] {
            return list.compactMap { step -> String? in
                // HowToStep or HowToSection
                if let text = step["text"] as? String {
                    return decodeHTMLEntities(stripHTML(text))
                }
                // HowToSection with itemListElement
                if let items = step["itemListElement"] as? [[String: Any]] {
                    return items.compactMap { $0["text"] as? String }
                        .map { decodeHTMLEntities(stripHTML($0)) }
                        .joined(separator: " ")
                }
                return nil
            }.filter { !$0.isEmpty }
        }
        
        // Handle simple string array
        if let list = dict["recipeInstructions"] as? [String] {
            return list.map { decodeHTMLEntities(stripHTML($0)) }.filter { !$0.isEmpty }
        }
        
        // Handle single string (sometimes with line breaks)
        if let str = dict["recipeInstructions"] as? String {
            let cleaned = decodeHTMLEntities(stripHTML(str))
            // Split by common delimiters
            let steps = cleaned.components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return steps
        }
        
        return []
    }

    func parseServings(from dict: [String: Any]) -> Int? {
        // Handle array of yields
        if let yields = dict["recipeYield"] as? [Any] {
            for yield in yields {
                if let yieldInt = yield as? Int, yieldInt > 0 {
                    return yieldInt
                }
                if let yieldStr = yield as? String, let parsed = extractNumber(from: yieldStr), parsed > 0 {
                    return parsed
                }
            }
        }
        
        // Handle string yield
        if let yield = dict["recipeYield"] as? String {
            if let parsed = extractNumber(from: yield), parsed > 0 {
                return parsed
            }
        }
        
        // Handle integer yield
        if let yieldInt = dict["recipeYield"] as? Int, yieldInt > 0 {
            return yieldInt
        }
        
        return nil
    }
    
    private func extractNumber(from string: String) -> Int? {
        let numbers = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(numbers)
    }
    
    // MARK: - Microdata Parsing
    
    private func extractMicrodataRecipe(from html: String, url: URL) -> Recipe? {
        // Look for itemtype="http://schema.org/Recipe" or itemtype="https://schema.org/Recipe"
        guard html.contains("schema.org/Recipe") else { return nil }
        
        let title = extractMicrodataProperty(html, property: "name") ?? "Imported Recipe"
        
        // Extract ingredients with itemprop="recipeIngredient" or itemprop="ingredients"
        var ingredients: [Ingredient] = []
        let ingredientPattern = "itemprop=[\"'](?:recipeIngredient|ingredients)[\"'][^>]*>([^<]+)<"
        if let regex = try? NSRegularExpression(pattern: ingredientPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if let range = Range(match.range(at: 1), in: html) {
                    let ingredientText = decodeHTMLEntities(String(html[range]))
                    ingredients.append(RecipeParserService.parseIngredientString(ingredientText))
                }
            }
        }
        
        // Extract instructions
        var instructions: [String] = []
        let instructionPattern = "itemprop=[\"']recipeInstructions[\"'][^>]*>([^<]+)<"
        if let regex = try? NSRegularExpression(pattern: instructionPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if let range = Range(match.range(at: 1), in: html) {
                    let step = decodeHTMLEntities(stripHTML(String(html[range])))
                    if !step.isEmpty {
                        instructions.append(step)
                    }
                }
            }
        }
        
        if title == "Imported Recipe" && ingredients.isEmpty && instructions.isEmpty {
            return nil
        }
        
        return Recipe(id: UUID(),
                      title: title,
                      ingredients: ingredients,
                      instructions: instructions,
                      sourceURL: url.absoluteString,
                      servings: nil,
                      imageAsset: nil)
    }
    
    private func extractMicrodataProperty(_ html: String, property: String) -> String? {
        let pattern = "itemprop=[\"']\(property)[\"'][^>]*>([^<]+)<"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              let matchRange = Range(match.range(at: 1), in: html) else { return nil }
        return decodeHTMLEntities(String(html[matchRange]))
    }

    // MARK: - Meta Tag Fallback
    
    private func extractMetaTagRecipe(from html: String, url: URL) -> Recipe? {
        let titlePattern = "<meta property=\"og:title\" content=\"([^\"]*)\""
        let title = extractMeta(pattern: titlePattern, from: html) ?? "Imported Recipe"

        if title == "Imported Recipe" { return nil }

        return Recipe(id: UUID(),
                      title: decodeHTMLEntities(title),
                      ingredients: [],
                      instructions: [],
                      sourceURL: url.absoluteString,
                      servings: nil,
                      imageAsset: nil)
    }

    private func extractMeta(pattern: String, from html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else { return nil }
        guard let range = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[range])
    }
    
    // MARK: - Utility Functions
    
    private func stripHTML(_ string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive) else {
            return string
        }
        let range = NSRange(string.startIndex..., in: string)
        return regex.stringByReplacingMatches(in: string, range: range, withTemplate: "")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&#x27;", "'"),
            ("&#x2F;", "/"),
            ("&nbsp;", " "),
            ("&deg;", "°"),
            ("&frac12;", "½"),
            ("&frac14;", "¼"),
            ("&frac34;", "¾"),
            ("&#8531;", "⅓"),
            ("&#8532;", "⅔"),
            ("&#xBD;", "½"),
            ("&#xBC;", "¼"),
            ("&#xBE;", "¾"),
            ("&#189;", "½"),
            ("&#188;", "¼"),
            ("&#190;", "¾")
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        
        // Handle numeric entities like &#8217;
        if let numericRegex = try? NSRegularExpression(pattern: "&#(\\d+);", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = numericRegex.matches(in: result, range: range).reversed()
            for match in matches {
                if let numRange = Range(match.range(at: 1), in: result),
                   let code = Int(result[numRange]),
                   let scalar = Unicode.Scalar(code) {
                    let charRange = Range(match.range, in: result)!
                    result.replaceSubrange(charRange, with: String(Character(scalar)))
                }
            }
        }
        
        return result
    }

    // MARK: - Ingredient Parsing
    
    static func parseIngredientString(_ raw: String) -> Ingredient {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle fractions at the start
        var workingString = cleaned
        var quantity: Double = 0
        
        // Check for unicode fractions
        let fractionMap: [(String, Double)] = [
            ("½", 0.5), ("¼", 0.25), ("¾", 0.75),
            ("⅓", 1.0/3.0), ("⅔", 2.0/3.0),
            ("⅛", 0.125), ("⅜", 0.375), ("⅝", 0.625), ("⅞", 0.875)
        ]
        
        // Try to parse leading number (including mixed fractions like "1 1/2")
        let scanner = Scanner(string: workingString)
        scanner.charactersToBeSkipped = nil
        
        if let wholeNumber = scanner.scanDouble() {
            quantity = wholeNumber
            workingString = String(workingString.dropFirst(scanner.currentIndex.utf16Offset(in: workingString)))
                .trimmingCharacters(in: .whitespaces)
            
            // Check for fraction after whole number
            for (frac, val) in fractionMap {
                if workingString.hasPrefix(frac) {
                    quantity += val
                    workingString = String(workingString.dropFirst(frac.count))
                        .trimmingCharacters(in: .whitespaces)
                    break
                }
            }
            
            // Check for text fraction like "1/2"
            if workingString.hasPrefix("/") || (workingString.first?.isNumber ?? false) {
                let fractionPattern = "^(\\d+)\\s*/\\s*(\\d+)"
                if let regex = try? NSRegularExpression(pattern: fractionPattern),
                   let match = regex.firstMatch(in: workingString, range: NSRange(workingString.startIndex..., in: workingString)),
                   let numRange = Range(match.range(at: 1), in: workingString),
                   let denRange = Range(match.range(at: 2), in: workingString),
                   let num = Double(workingString[numRange]),
                   let den = Double(workingString[denRange]), den != 0 {
                    quantity += num / den
                    workingString = String(workingString[workingString.index(workingString.startIndex, offsetBy: match.range.length)...])
                        .trimmingCharacters(in: .whitespaces)
                }
            }
        } else {
            // Check for leading unicode fraction
            for (frac, val) in fractionMap {
                if workingString.hasPrefix(frac) {
                    quantity = val
                    workingString = String(workingString.dropFirst(frac.count))
                        .trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        
        // Now parse unit and name
        let commonUnits = [
            "cups", "cup", "c",
            "tablespoons", "tablespoon", "tbsp", "tbsps", "tbs", "T",
            "teaspoons", "teaspoon", "tsp", "tsps", "t",
            "ounces", "ounce", "oz",
            "pounds", "pound", "lbs", "lb",
            "grams", "gram", "g",
            "kilograms", "kilogram", "kg",
            "milliliters", "milliliter", "ml",
            "liters", "liter", "l",
            "pinch", "pinches",
            "dash", "dashes",
            "cloves", "clove",
            "slices", "slice",
            "pieces", "piece",
            "cans", "can",
            "packages", "package", "pkg",
            "bunches", "bunch",
            "sprigs", "sprig",
            "stalks", "stalk",
            "heads", "head",
            "large", "medium", "small"
        ]
        
        let parts = workingString.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var unit = ""
        var nameParts: [String] = []
        var foundUnit = false
        
        for (index, part) in parts.enumerated() {
            if !foundUnit && commonUnits.contains(part.lowercased()) {
                unit = part
                foundUnit = true
            } else if !foundUnit && index == 0 {
                // First part might be a unit even if not in common list
                // Check if it looks like a unit (short, no digits after first char)
                if part.count <= 4 && part.first?.isLetter == true {
                    unit = part
                    foundUnit = true
                } else {
                    nameParts.append(part)
                }
            } else {
                nameParts.append(part)
            }
        }
        
        let name = nameParts.joined(separator: " ")
        
        // If we have no name but have a unit, the "unit" is probably the name
        if name.isEmpty && !unit.isEmpty {
            return Ingredient(id: UUID(), name: unit, quantity: quantity, units: "")
        }
        
        return Ingredient(id: UUID(), name: name.isEmpty ? raw : name, quantity: quantity, units: unit)
    }
}

// MARK: - Site-Specific Parsers

/// AllRecipes parser - handles their specific JSON-LD format
struct AllRecipesParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["allrecipes.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        // AllRecipes uses standard JSON-LD but sometimes has multiple recipe objects
        // The main parser should handle this, so this is just a hook for future customization
        return nil // Fall through to generic parser
    }
}

/// Serious Eats parser
struct SeriousEatsParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["seriouseats.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}

/// NYT Cooking parser - handles their paywall-friendly structure
struct NYTCookingParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["cooking.nytimes.com", "nytimes.com/recipe"]
    
    func parse(html: String, url: URL) -> Recipe? {
        // NYT Cooking uses standard JSON-LD
        return nil
    }
}

/// Food Network parser
struct FoodNetworkParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["foodnetwork.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}

/// Sally's Baking Addiction parser
struct SallysBakingParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["sallysbakingaddiction.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD via WordPress recipe plugin
    }
}

/// RecipeTin Eats parser
struct RecipeTinEatsParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["recipetineats.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD via WordPress recipe plugin
    }
}

/// Budget Bytes parser
struct BudgetBytesParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["budgetbytes.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}

/// The Kitchn parser
struct TheKitchnParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["thekitchn.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}

/// Simply Recipes parser
struct SimplyRecipesParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["simplyrecipes.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}

/// Epicurious parser
struct EpicuriousParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["epicurious.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}

/// Smitten Kitchen parser
struct SmittenKitchenParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["smittenkitchen.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        // Smitten Kitchen sometimes has recipes in blog post format without structured data
        // Try to extract from post content if JSON-LD fails
        return nil
    }
}

/// Love and Lemons parser
struct LoveAndLemonsParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["loveandlemons.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD via WordPress recipe plugin
    }
}

/// BBC Good Food parser
struct BBCGoodFoodParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["bbcgoodfood.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}

/// Delish parser
struct DelishParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["delish.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}

/// Taste of Home parser
struct TasteOfHomeParser: SiteSpecificParser {
    static var supportedHosts: [String] = ["tasteofhome.com"]
    
    func parse(html: String, url: URL) -> Recipe? {
        return nil // Uses standard JSON-LD
    }
}
