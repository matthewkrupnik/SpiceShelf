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

// MARK: - Main Parser Service

final class RecipeParserService: RecipeParserServiceProtocol, @unchecked Sendable {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    func parseRecipe(from url: URL) async throws -> Recipe {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw RecipeParsingError.invalidData
        }
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw RecipeParsingError.invalidData
        }

        if let recipe = extractJSONLDRecipe(from: htmlString, url: url) {
            return recipe
        }

        if let recipe = extractMicrodataRecipe(from: htmlString, url: url) {
            return recipe
        }

        if let recipe = extractMetaTagRecipe(from: htmlString, url: url) {
            return recipe
        }

        throw RecipeParsingError.noRecipeFound
    }

    // MARK: - JSON-LD Parsing
    
    func extractJSONLDRecipe(from html: String, url: URL) -> Recipe? {
        let pattern = "<script\\b[^>]*?\\btype=[\"']application/ld\\+json[\"'][^>]*>(.*?)</script>"
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
            
            // Recursively search all keys for Recipe type
            // This handles @graph, mainEntity, and any other nesting
            for value in dict.values {
                if let recipe = findRecipeInJSON(value, url: url) {
                    return recipe
                }
            }
        }
        
        // Array of items
        if let array = json as? [Any] {
            for item in array {
                if let recipe = findRecipeInJSON(item, url: url) {
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

        // Core properties
        let name = extractTitle(from: dict)
        let recipeDescription = extractDescription(from: dict)
        let author = extractAuthor(from: dict)
        let images = extractImages(from: dict)
        let datePublished = extractDatePublished(from: dict)
        let keywords = extractKeywords(from: dict)
        
        // Recipe content
        let ingredients = parseIngredients(from: dict)
        let (instructionSteps, instructionSections) = parseInstructions(from: dict)
        let (recipeYield, servings) = parseYield(from: dict)
        
        // Classification
        let recipeCategory = extractString(from: dict, key: "recipeCategory")
        let recipeCuisine = extractString(from: dict, key: "recipeCuisine")
        let cookingMethod = extractString(from: dict, key: "cookingMethod")
        let suitableForDiet = extractDiets(from: dict)
        
        // Time
        let prepTime = extractDuration(from: dict, key: "prepTime")
        let cookTime = extractDuration(from: dict, key: "cookTime")
        let totalTime = extractDuration(from: dict, key: "totalTime")
        
        // Nutrition & Rating
        let nutrition = extractNutrition(from: dict)
        let aggregateRating = extractAggregateRating(from: dict)
        
        // Video
        let video = extractVideo(from: dict)

        return Recipe(
            id: UUID(),
            name: name,
            recipeDescription: recipeDescription,
            author: author,
            images: images,
            datePublished: datePublished,
            keywords: keywords,
            recipeIngredient: ingredients,
            instructionSteps: instructionSteps,
            instructionSections: instructionSections,
            recipeYield: recipeYield,
            servings: servings,
            recipeCategory: recipeCategory,
            recipeCuisine: recipeCuisine,
            cookingMethod: cookingMethod,
            suitableForDiet: suitableForDiet,
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            nutrition: nutrition,
            aggregateRating: aggregateRating,
            video: video,
            sourceURL: url.absoluteString,
            imageAsset: nil
        )
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
    
    // MARK: - Schema.org Field Extraction
    
    private func extractDescription(from dict: [String: Any]) -> String? {
        if let desc = dict["description"] as? String, !desc.isEmpty {
            return decodeHTMLEntities(stripHTML(desc))
        }
        return nil
    }
    
    private func extractAuthor(from dict: [String: Any]) -> RecipeAuthor? {
        // Author can be a string, object, or array
        if let authorStr = dict["author"] as? String, !authorStr.isEmpty {
            return RecipeAuthor(name: decodeHTMLEntities(authorStr), url: nil)
        }
        
        if let authorDict = dict["author"] as? [String: Any] {
            let name = authorDict["name"] as? String
            let url = authorDict["url"] as? String
            if name != nil || url != nil {
                return RecipeAuthor(name: name.map { decodeHTMLEntities($0) }, url: url)
            }
        }
        
        if let authors = dict["author"] as? [[String: Any]], let first = authors.first {
            let name = first["name"] as? String
            let url = first["url"] as? String
            if name != nil || url != nil {
                return RecipeAuthor(name: name.map { decodeHTMLEntities($0) }, url: url)
            }
        }
        
        return nil
    }
    
    private func extractImages(from dict: [String: Any]) -> [String]? {
        // Image can be a string, object, or array
        if let imageStr = dict["image"] as? String, !imageStr.isEmpty {
            return [imageStr]
        }
        
        if let imageDict = dict["image"] as? [String: Any],
           let url = imageDict["url"] as? String {
            return [url]
        }
        
        if let images = dict["image"] as? [String] {
            let filtered = images.filter { !$0.isEmpty }
            return filtered.isEmpty ? nil : filtered
        }
        
        if let images = dict["image"] as? [[String: Any]] {
            let urls = images.compactMap { $0["url"] as? String }
            return urls.isEmpty ? nil : urls
        }
        
        return nil
    }
    
    private func extractDatePublished(from dict: [String: Any]) -> Date? {
        guard let dateStr = dict["datePublished"] as? String else { return nil }
        
        let formatters: [DateFormatter] = {
            let iso8601 = DateFormatter()
            iso8601.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
            let iso8601NoTZ = DateFormatter()
            iso8601NoTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            
            let dateOnly = DateFormatter()
            dateOnly.dateFormat = "yyyy-MM-dd"
            
            return [iso8601, iso8601NoTZ, dateOnly]
        }()
        
        for formatter in formatters {
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        return nil
    }
    
    private func extractKeywords(from dict: [String: Any]) -> [String]? {
        // Keywords can be a comma-separated string or array
        if let keywordsStr = dict["keywords"] as? String, !keywordsStr.isEmpty {
            let keywords = keywordsStr
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return keywords.isEmpty ? nil : keywords
        }
        
        if let keywords = dict["keywords"] as? [String] {
            let filtered = keywords.filter { !$0.isEmpty }
            return filtered.isEmpty ? nil : filtered
        }
        
        return nil
    }
    
    private func extractString(from dict: [String: Any], key: String) -> String? {
        // Handle both string and array (take first)
        if let str = dict[key] as? String, !str.isEmpty {
            return decodeHTMLEntities(str)
        }
        if let arr = dict[key] as? [String], let first = arr.first, !first.isEmpty {
            return decodeHTMLEntities(first)
        }
        return nil
    }
    
    private func extractDiets(from dict: [String: Any]) -> [String]? {
        // suitableForDiet can be string or array
        if let diet = dict["suitableForDiet"] as? String, !diet.isEmpty {
            return [diet]
        }
        if let diets = dict["suitableForDiet"] as? [String] {
            let filtered = diets.filter { !$0.isEmpty }
            return filtered.isEmpty ? nil : filtered
        }
        return nil
    }
    
    private func extractDuration(from dict: [String: Any], key: String) -> RecipeDuration? {
        guard let durationStr = dict[key] as? String, !durationStr.isEmpty else { return nil }
        let duration = RecipeDuration.fromISO8601(durationStr)
        return duration.totalMinutes != nil ? duration : nil
    }
    
    private func extractNutrition(from dict: [String: Any]) -> NutritionInfo? {
        guard let nutritionDict = dict["nutrition"] as? [String: Any] else { return nil }
        
        let info = NutritionInfo(
            calories: nutritionDict["calories"] as? String,
            fatContent: nutritionDict["fatContent"] as? String,
            saturatedFatContent: nutritionDict["saturatedFatContent"] as? String,
            cholesterolContent: nutritionDict["cholesterolContent"] as? String,
            sodiumContent: nutritionDict["sodiumContent"] as? String,
            carbohydrateContent: nutritionDict["carbohydrateContent"] as? String,
            fiberContent: nutritionDict["fiberContent"] as? String,
            sugarContent: nutritionDict["sugarContent"] as? String,
            proteinContent: nutritionDict["proteinContent"] as? String,
            servingSize: nutritionDict["servingSize"] as? String
        )
        
        // Only return if at least one field is present
        if info.calories != nil || info.fatContent != nil || info.proteinContent != nil ||
           info.carbohydrateContent != nil || info.sodiumContent != nil {
            return info
        }
        return nil
    }
    
    private func extractAggregateRating(from dict: [String: Any]) -> AggregateRating? {
        guard let ratingDict = dict["aggregateRating"] as? [String: Any] else { return nil }
        
        let ratingValue: Double? = {
            if let val = ratingDict["ratingValue"] as? Double { return val }
            if let val = ratingDict["ratingValue"] as? Int { return Double(val) }
            if let str = ratingDict["ratingValue"] as? String { return Double(str) }
            return nil
        }()
        
        let ratingCount: Int? = {
            if let val = ratingDict["ratingCount"] as? Int { return val }
            if let str = ratingDict["ratingCount"] as? String { return Int(str) }
            return nil
        }()
        
        let reviewCount: Int? = {
            if let val = ratingDict["reviewCount"] as? Int { return val }
            if let str = ratingDict["reviewCount"] as? String { return Int(str) }
            return nil
        }()
        
        if ratingValue != nil || ratingCount != nil || reviewCount != nil {
            return AggregateRating(
                ratingValue: ratingValue,
                ratingCount: ratingCount,
                reviewCount: reviewCount,
                bestRating: ratingDict["bestRating"] as? Double ?? 5,
                worstRating: ratingDict["worstRating"] as? Double ?? 1
            )
        }
        return nil
    }
    
    private func extractVideo(from dict: [String: Any]) -> RecipeVideo? {
        guard let videoDict = dict["video"] as? [String: Any] else { return nil }
        
        // Extract thumbnails (can be string or array)
        var thumbnails: [String]? = nil
        if let thumb = videoDict["thumbnailUrl"] as? String {
            thumbnails = [thumb]
        } else if let thumbs = videoDict["thumbnailUrl"] as? [String] {
            thumbnails = thumbs.filter { !$0.isEmpty }
        }
        
        // Extract upload date
        var uploadDate: Date? = nil
        if let dateStr = videoDict["uploadDate"] as? String {
            uploadDate = ISO8601DateFormatter().date(from: dateStr)
        }
        
        // Extract duration
        var duration: RecipeDuration? = nil
        if let durationStr = videoDict["duration"] as? String {
            duration = RecipeDuration.fromISO8601(durationStr)
        }
        
        let video = RecipeVideo(
            name: videoDict["name"] as? String,
            videoDescription: videoDict["description"] as? String,
            thumbnailUrl: thumbnails,
            contentUrl: videoDict["contentUrl"] as? String,
            embedUrl: videoDict["embedUrl"] as? String,
            uploadDate: uploadDate,
            duration: duration
        )
        
        // Only return if at least one meaningful field is present
        if video.contentUrl != nil || video.embedUrl != nil || video.name != nil {
            return video
        }
        return nil
    }

    func parseIngredients(from dict: [String: Any]) -> [Ingredient] {
        guard let ingredientList = dict["recipeIngredient"] as? [String] else { return [] }
        return ingredientList.map { RecipeParserService.parseIngredientString(decodeHTMLEntities($0)) }
    }

    func parseInstructions(from dict: [String: Any]) -> ([HowToStep], [HowToSection]?) {
        var steps: [HowToStep] = []
        var sections: [HowToSection] = []
        
        let instructions = dict["recipeInstructions"]
        
        // Helper to extract step from a dict
        func extractStep(from item: [String: Any]) -> HowToStep? {
            if let text = item["text"] as? String, !text.isEmpty {
                return HowToStep(
                    name: item["name"] as? String,
                    text: decodeHTMLEntities(stripHTML(text)),
                    url: item["url"] as? String,
                    image: extractStepImage(from: item)
                )
            }
            return nil
        }

        // Handle case where instructions is a single object (ItemList or similar)
        if let instrDict = instructions as? [String: Any] {
            if let itemList = instrDict["itemListElement"] as? [[String: Any]] {
                for item in itemList {
                    if let step = extractStep(from: item) {
                        steps.append(step)
                    }
                }
            } else if let step = extractStep(from: instrDict) {
                steps.append(step)
            }
        }
        
        // Handle array of objects or strings
        else if let list = instructions as? [Any] {
            for item in list {
                // Dictionary item (HowToStep or HowToSection)
                if let itemDict = item as? [String: Any] {
                    let itemType = itemDict["@type"] as? String
                    
                    // HowToSection
                    if itemType == "HowToSection" {
                        let sectionName = itemDict["name"] as? String ?? "Section"
                        var sectionSteps: [HowToStep] = []
                        
                        if let items = itemDict["itemListElement"] as? [[String: Any]] {
                            for stepItem in items {
                                if let step = extractStep(from: stepItem) {
                                    sectionSteps.append(step)
                                }
                            }
                        }
                        
                        if !sectionSteps.isEmpty {
                            sections.append(HowToSection(name: sectionName, steps: sectionSteps))
                        }
                    }
                    // HowToStep (or any dict with "text")
                    else if let step = extractStep(from: itemDict) {
                        steps.append(step)
                    }
                }
                // Plain string item
                else if let str = item as? String {
                    let cleaned = decodeHTMLEntities(stripHTML(str))
                    if !cleaned.isEmpty {
                        steps.append(HowToStep(cleaned))
                    }
                }
            }
        }
        
        // Handle single string (sometimes with line breaks)
        else if let str = instructions as? String {
            let cleaned = decodeHTMLEntities(stripHTML(str))
            steps = cleaned.components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .map { HowToStep($0) }
        }
        
        return (steps, sections.isEmpty ? nil : sections)
    }
    
    private func extractStepImage(from step: [String: Any]) -> String? {
        if let imageStr = step["image"] as? String {
            return imageStr
        }
        if let imageDict = step["image"] as? [String: Any] {
            return imageDict["url"] as? String
        }
        return nil
    }

    func parseServings(from dict: [String: Any]) -> Int? {
        return parseYield(from: dict).1
    }
    
    func parseYield(from dict: [String: Any]) -> (String?, Int?) {
        var yieldString: String? = nil
        var servings: Int? = nil
        
        // Handle array of yields
        if let yields = dict["recipeYield"] as? [Any] {
            for yield in yields {
                if let yieldInt = yield as? Int, yieldInt > 0 {
                    servings = yieldInt
                    yieldString = "\(yieldInt) servings"
                    break
                }
                if let yieldStr = yield as? String {
                    yieldString = decodeHTMLEntities(yieldStr)
                    if let parsed = extractNumber(from: yieldStr), parsed > 0 {
                        servings = parsed
                    }
                    break
                }
            }
            return (yieldString, servings)
        }
        
        // Handle string yield
        if let yield = dict["recipeYield"] as? String {
            yieldString = decodeHTMLEntities(yield)
            if let parsed = extractNumber(from: yield), parsed > 0 {
                servings = parsed
            }
            return (yieldString, servings)
        }
        
        // Handle integer yield
        if let yieldInt = dict["recipeYield"] as? Int, yieldInt > 0 {
            return ("\(yieldInt) servings", yieldInt)
        }
        
        return (nil, nil)
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
            
            // Check for text fraction like "1/2" or "1 1/2"
            if workingString.hasPrefix("/") {
                let denomPattern = "^/\\s*(\\d+)"
                if let regex = try? NSRegularExpression(pattern: denomPattern),
                   let match = regex.firstMatch(in: workingString, range: NSRange(workingString.startIndex..., in: workingString)),
                   let denRange = Range(match.range(at: 1), in: workingString),
                   let den = Double(workingString[denRange]), den != 0 {
                    quantity = quantity / den
                    workingString = String(workingString[workingString.index(workingString.startIndex, offsetBy: match.range.length)...])
                        .trimmingCharacters(in: .whitespaces)
                }
            } else if workingString.first?.isNumber ?? false {
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
