import Foundation
import CloudKit

// MARK: - Schema.org Recipe Model
// Based on https://schema.org/Recipe specification

/// Nutrition information for a recipe (Schema.org NutritionInformation)
struct NutritionInfo: Codable, Hashable {
    var calories: String?           // e.g., "240 calories"
    var fatContent: String?         // e.g., "9 grams"
    var saturatedFatContent: String?
    var cholesterolContent: String?
    var sodiumContent: String?
    var carbohydrateContent: String?
    var fiberContent: String?
    var sugarContent: String?
    var proteinContent: String?
    var servingSize: String?        // e.g., "1 slice"
}

/// Duration representation for cook/prep times (ISO 8601 format)
struct RecipeDuration: Codable, Hashable {
    var iso8601: String?  // Original ISO 8601 string (e.g., "PT1H30M")
    var totalMinutes: Int?
    
    init(iso8601: String? = nil, totalMinutes: Int? = nil) {
        self.iso8601 = iso8601
        self.totalMinutes = totalMinutes
    }
    
    init(minutes: Int) {
        self.totalMinutes = minutes
        self.iso8601 = RecipeDuration.toISO8601(minutes: minutes)
    }
    
    /// Parse ISO 8601 duration (e.g., "PT1H30M" = 90 minutes)
    static func fromISO8601(_ string: String) -> RecipeDuration {
        var duration = RecipeDuration(iso8601: string)
        
        let pattern = "PT(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            return duration
        }
        
        var minutes = 0
        
        // Hours
        if let range = Range(match.range(at: 1), in: string), let hours = Int(string[range]) {
            minutes += hours * 60
        }
        // Minutes
        if let range = Range(match.range(at: 2), in: string), let mins = Int(string[range]) {
            minutes += mins
        }
        // Seconds (round up to minute)
        if let range = Range(match.range(at: 3), in: string), let secs = Int(string[range]) {
            minutes += (secs + 59) / 60
        }
        
        duration.totalMinutes = minutes > 0 ? minutes : nil
        return duration
    }
    
    static func toISO8601(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "PT\(hours)H\(mins)M"
        } else if hours > 0 {
            return "PT\(hours)H"
        } else {
            return "PT\(mins)M"
        }
    }
    
    /// Human-readable format (e.g., "1 hr 30 min")
    var displayString: String? {
        guard let total = totalMinutes, total > 0 else { return nil }
        let hours = total / 60
        let mins = total % 60
        if hours > 0 && mins > 0 {
            return "\(hours) hr \(mins) min"
        } else if hours > 0 {
            return "\(hours) hr"
        } else {
            return "\(mins) min"
        }
    }
}

/// Aggregate rating information (Schema.org AggregateRating)
struct AggregateRating: Codable, Hashable {
    var ratingValue: Double?    // e.g., 4.5
    var ratingCount: Int?       // Number of ratings
    var reviewCount: Int?       // Number of reviews
    var bestRating: Double?     // e.g., 5
    var worstRating: Double?    // e.g., 1
}

/// Author/creator information (Schema.org Person or Organization)
struct RecipeAuthor: Codable, Hashable {
    var name: String?
    var url: String?
}

/// Recipe model based on Schema.org Recipe type
/// https://schema.org/Recipe
struct Recipe: Identifiable, Hashable, Codable {
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Core Properties (Thing > CreativeWork > Recipe)
    
    var id: UUID
    
    /// The name of the recipe (Schema.org: name)
    var name: String
    
    /// A description of the recipe (Schema.org: description)
    var recipeDescription: String?
    
    /// The author/creator (Schema.org: author)
    var author: RecipeAuthor?
    
    /// URL of the image (Schema.org: image)
    var imageURL: String?
    
    /// Date published (Schema.org: datePublished)
    var datePublished: Date?
    
    /// Keywords/tags (Schema.org: keywords)
    var keywords: [String]?
    
    // MARK: - Recipe-Specific Properties
    
    /// List of ingredients (Schema.org: recipeIngredient)
    var recipeIngredient: [Ingredient]
    
    /// Step-by-step instructions (Schema.org: recipeInstructions)
    var recipeInstructions: [String]
    
    /// Quantity produced (Schema.org: recipeYield)
    /// Can be servings count or descriptive (e.g., "1 loaf", "4 servings")
    var recipeYield: String?
    
    /// Servings count (parsed from recipeYield when numeric)
    var servings: Int?
    
    /// Category (Schema.org: recipeCategory) - e.g., "appetizer", "entree", "dessert"
    var recipeCategory: String?
    
    /// Cuisine type (Schema.org: recipeCuisine) - e.g., "French", "Italian"
    var recipeCuisine: String?
    
    /// Cooking method (Schema.org: cookingMethod) - e.g., "Frying", "Baking"
    var cookingMethod: String?
    
    /// Suitable diets (Schema.org: suitableForDiet) - e.g., "VegetarianDiet", "GlutenFreeDiet"
    var suitableForDiet: [String]?
    
    // MARK: - Time Properties
    
    /// Time to prepare ingredients (Schema.org: prepTime)
    var prepTime: RecipeDuration?
    
    /// Time to cook (Schema.org: cookTime)
    var cookTime: RecipeDuration?
    
    /// Total time including prep (Schema.org: totalTime)
    var totalTime: RecipeDuration?
    
    // MARK: - Nutrition & Ratings
    
    /// Nutritional information (Schema.org: nutrition)
    var nutrition: NutritionInfo?
    
    /// Aggregate rating (Schema.org: aggregateRating)
    var aggregateRating: AggregateRating?
    
    // MARK: - Source & Metadata
    
    /// Source URL where recipe was imported from (Schema.org: url)
    var sourceURL: String?
    
    // MARK: - App-Specific (not in Schema.org)
    
    /// CloudKit image asset (not codable, handled separately)
    var imageAsset: CKAsset? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, name, recipeDescription, author, imageURL, datePublished, keywords
        case recipeIngredient, recipeInstructions, recipeYield, servings
        case recipeCategory, recipeCuisine, cookingMethod, suitableForDiet
        case prepTime, cookTime, totalTime
        case nutrition, aggregateRating, sourceURL
    }
    
    // MARK: - Backward Compatibility
    
    /// Alias for `name` to maintain backward compatibility
    var title: String {
        get { name }
        set { name = newValue }
    }
    
    /// Alias for `recipeIngredient` to maintain backward compatibility
    var ingredients: [Ingredient] {
        get { recipeIngredient }
        set { recipeIngredient = newValue }
    }
    
    /// Alias for `recipeInstructions` to maintain backward compatibility
    var instructions: [String] {
        get { recipeInstructions }
        set { recipeInstructions = newValue }
    }
    
    // MARK: - Initializers
    
    /// Full initializer with all Schema.org properties
    init(
        id: UUID = UUID(),
        name: String,
        recipeDescription: String? = nil,
        author: RecipeAuthor? = nil,
        imageURL: String? = nil,
        datePublished: Date? = nil,
        keywords: [String]? = nil,
        recipeIngredient: [Ingredient] = [],
        recipeInstructions: [String] = [],
        recipeYield: String? = nil,
        servings: Int? = nil,
        recipeCategory: String? = nil,
        recipeCuisine: String? = nil,
        cookingMethod: String? = nil,
        suitableForDiet: [String]? = nil,
        prepTime: RecipeDuration? = nil,
        cookTime: RecipeDuration? = nil,
        totalTime: RecipeDuration? = nil,
        nutrition: NutritionInfo? = nil,
        aggregateRating: AggregateRating? = nil,
        sourceURL: String? = nil,
        imageAsset: CKAsset? = nil
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = recipeDescription
        self.author = author
        self.imageURL = imageURL
        self.datePublished = datePublished
        self.keywords = keywords
        self.recipeIngredient = recipeIngredient
        self.recipeInstructions = recipeInstructions
        self.recipeYield = recipeYield
        self.servings = servings
        self.recipeCategory = recipeCategory
        self.recipeCuisine = recipeCuisine
        self.cookingMethod = cookingMethod
        self.suitableForDiet = suitableForDiet
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.nutrition = nutrition
        self.aggregateRating = aggregateRating
        self.sourceURL = sourceURL
        self.imageAsset = imageAsset
    }
    
    /// Backward-compatible initializer matching original Recipe
    init(
        id: UUID,
        title: String,
        ingredients: [Ingredient],
        instructions: [String],
        sourceURL: String? = nil,
        servings: Int? = nil,
        imageAsset: CKAsset? = nil
    ) {
        self.id = id
        self.name = title
        self.recipeIngredient = ingredients
        self.recipeInstructions = instructions
        self.sourceURL = sourceURL
        self.servings = servings
        self.imageAsset = imageAsset
        
        // Initialize other properties to nil
        self.recipeDescription = nil
        self.author = nil
        self.imageURL = nil
        self.datePublished = nil
        self.keywords = nil
        self.recipeYield = servings != nil ? "\(servings!) servings" : nil
        self.recipeCategory = nil
        self.recipeCuisine = nil
        self.cookingMethod = nil
        self.suitableForDiet = nil
        self.prepTime = nil
        self.cookTime = nil
        self.totalTime = nil
        self.nutrition = nil
        self.aggregateRating = nil
    }
}
