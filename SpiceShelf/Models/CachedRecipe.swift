import Foundation
import SwiftData
import CloudKit

@Model
final class CachedIngredient {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: Double = 0
    var units: String = ""
    var rawText: String?
    
    // Inverse relationship
    var recipe: CachedRecipe?
    
    init(id: UUID = UUID(), name: String = "", quantity: Double = 0, units: String = "", rawText: String? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.units = units
        self.rawText = rawText
    }
    
    convenience init(from ingredient: Ingredient) {
        self.init(id: ingredient.id, name: ingredient.name, quantity: ingredient.quantity, units: ingredient.units, rawText: ingredient.rawText)
    }
    
    func toIngredient() -> Ingredient {
        Ingredient(id: id, name: name, quantity: quantity, units: units, rawText: rawText)
    }
}

@Model
final class CachedRecipe {
    var id: UUID = UUID()
    
    // Core properties (Schema.org)
    var name: String = ""
    var recipeDescription: String?
    var authorName: String?
    var authorURL: String?
    var imageURL: String?
    var datePublished: Date?
    var keywords: [String]?
    
    // Recipe content
    @Relationship(deleteRule: .cascade, inverse: \CachedIngredient.recipe)
    var ingredients: [CachedIngredient]? = []
    var instructions: [String] = []
    var recipeYield: String?
    var servings: Int?
    
    // Classification
    var recipeCategory: String?
    var recipeCuisine: String?
    var cookingMethod: String?
    var suitableForDiet: [String]?
    
    // Time (stored as minutes for simplicity)
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var totalTimeMinutes: Int?
    
    // Nutrition (stored as JSON string for flexibility)
    var nutritionJSON: String?
    
    // Rating
    var ratingValue: Double?
    var ratingCount: Int?
    
    // Source
    var sourceURL: String?
    
    // App-specific
    var imageData: Data?
    
    // Sync tracking
    var lastModified: Date = Date()
    var needsSync: Bool = false
    var syncStatus: String = "synced" // "synced", "pendingUpload", "pendingDelete"
    
    // Backward compatibility alias
    var title: String {
        get { name }
        set { name = newValue }
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        recipeDescription: String? = nil,
        authorName: String? = nil,
        authorURL: String? = nil,
        imageURL: String? = nil,
        datePublished: Date? = nil,
        keywords: [String]? = nil,
        ingredients: [CachedIngredient] = [],
        instructions: [String] = [],
        recipeYield: String? = nil,
        servings: Int? = nil,
        recipeCategory: String? = nil,
        recipeCuisine: String? = nil,
        cookingMethod: String? = nil,
        suitableForDiet: [String]? = nil,
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        totalTimeMinutes: Int? = nil,
        nutritionJSON: String? = nil,
        ratingValue: Double? = nil,
        ratingCount: Int? = nil,
        sourceURL: String? = nil,
        imageData: Data? = nil,
        lastModified: Date = Date(),
        needsSync: Bool = false,
        syncStatus: String = "synced"
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = recipeDescription
        self.authorName = authorName
        self.authorURL = authorURL
        self.imageURL = imageURL
        self.datePublished = datePublished
        self.keywords = keywords
        self.ingredients = ingredients
        self.instructions = instructions
        self.recipeYield = recipeYield
        self.servings = servings
        self.recipeCategory = recipeCategory
        self.recipeCuisine = recipeCuisine
        self.cookingMethod = cookingMethod
        self.suitableForDiet = suitableForDiet
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.totalTimeMinutes = totalTimeMinutes
        self.nutritionJSON = nutritionJSON
        self.ratingValue = ratingValue
        self.ratingCount = ratingCount
        self.sourceURL = sourceURL
        self.imageData = imageData
        self.lastModified = lastModified
        self.needsSync = needsSync
        self.syncStatus = syncStatus
    }
    
    convenience init(from recipe: Recipe) {
        var imageData: Data? = nil
        if let asset = recipe.imageAsset,
           let url = asset.fileURL,
           let data = try? Data(contentsOf: url) {
            imageData = data
        }
        
        // Encode nutrition as JSON
        var nutritionJSON: String? = nil
        if let nutrition = recipe.nutrition,
           let data = try? JSONEncoder().encode(nutrition) {
            nutritionJSON = String(data: data, encoding: .utf8)
        }
        
        self.init(
            id: recipe.id,
            name: recipe.name,
            recipeDescription: recipe.recipeDescription,
            authorName: recipe.author?.name,
            authorURL: recipe.author?.url,
            imageURL: recipe.imageURL,
            datePublished: recipe.datePublished,
            keywords: recipe.keywords,
            ingredients: recipe.recipeIngredient.map { CachedIngredient(from: $0) },
            instructions: recipe.recipeInstructions,
            recipeYield: recipe.recipeYield,
            servings: recipe.servings,
            recipeCategory: recipe.recipeCategory,
            recipeCuisine: recipe.recipeCuisine,
            cookingMethod: recipe.cookingMethod,
            suitableForDiet: recipe.suitableForDiet,
            prepTimeMinutes: recipe.prepTime?.totalMinutes,
            cookTimeMinutes: recipe.cookTime?.totalMinutes,
            totalTimeMinutes: recipe.totalTime?.totalMinutes,
            nutritionJSON: nutritionJSON,
            ratingValue: recipe.aggregateRating?.ratingValue,
            ratingCount: recipe.aggregateRating?.ratingCount,
            sourceURL: recipe.sourceURL,
            imageData: imageData,
            lastModified: Date(),
            needsSync: false,
            syncStatus: "synced"
        )
    }
    
    func toRecipe() -> Recipe {
        // Decode nutrition from JSON
        var nutrition: NutritionInfo? = nil
        if let json = nutritionJSON,
           let data = json.data(using: .utf8) {
            nutrition = try? JSONDecoder().decode(NutritionInfo.self, from: data)
        }
        
        // Build author if present
        var author: RecipeAuthor? = nil
        if authorName != nil || authorURL != nil {
            author = RecipeAuthor(name: authorName, url: authorURL)
        }
        
        // Build aggregate rating if present
        var aggregateRating: AggregateRating? = nil
        if ratingValue != nil || ratingCount != nil {
            aggregateRating = AggregateRating(ratingValue: ratingValue, ratingCount: ratingCount)
        }
        
        return Recipe(
            id: id,
            name: name,
            recipeDescription: recipeDescription,
            author: author,
            imageURL: imageURL,
            datePublished: datePublished,
            keywords: keywords,
            recipeIngredient: (ingredients ?? []).map { $0.toIngredient() },
            recipeInstructions: instructions,
            recipeYield: recipeYield,
            servings: servings,
            recipeCategory: recipeCategory,
            recipeCuisine: recipeCuisine,
            cookingMethod: cookingMethod,
            suitableForDiet: suitableForDiet,
            prepTime: prepTimeMinutes != nil ? RecipeDuration(minutes: prepTimeMinutes!) : nil,
            cookTime: cookTimeMinutes != nil ? RecipeDuration(minutes: cookTimeMinutes!) : nil,
            totalTime: totalTimeMinutes != nil ? RecipeDuration(minutes: totalTimeMinutes!) : nil,
            nutrition: nutrition,
            aggregateRating: aggregateRating,
            sourceURL: sourceURL,
            imageAsset: nil // CKAsset will be handled by CloudKit service when syncing
        )
    }
    
    func update(from recipe: Recipe) {
        self.name = recipe.name
        self.recipeDescription = recipe.recipeDescription
        self.authorName = recipe.author?.name
        self.authorURL = recipe.author?.url
        self.imageURL = recipe.imageURL
        self.datePublished = recipe.datePublished
        self.keywords = recipe.keywords
        self.instructions = recipe.recipeInstructions
        self.recipeYield = recipe.recipeYield
        self.servings = recipe.servings
        self.recipeCategory = recipe.recipeCategory
        self.recipeCuisine = recipe.recipeCuisine
        self.cookingMethod = recipe.cookingMethod
        self.suitableForDiet = recipe.suitableForDiet
        self.prepTimeMinutes = recipe.prepTime?.totalMinutes
        self.cookTimeMinutes = recipe.cookTime?.totalMinutes
        self.totalTimeMinutes = recipe.totalTime?.totalMinutes
        self.ratingValue = recipe.aggregateRating?.ratingValue
        self.ratingCount = recipe.aggregateRating?.ratingCount
        self.sourceURL = recipe.sourceURL
        self.lastModified = Date()
        
        // Update nutrition JSON
        if let nutrition = recipe.nutrition,
           let data = try? JSONEncoder().encode(nutrition) {
            self.nutritionJSON = String(data: data, encoding: .utf8)
        } else {
            self.nutritionJSON = nil
        }
        
        // Update image data if available
        if let asset = recipe.imageAsset,
           let url = asset.fileURL,
           let data = try? Data(contentsOf: url) {
            self.imageData = data
        }
        
        // Update ingredients
        self.ingredients?.removeAll()
        self.ingredients = recipe.recipeIngredient.map { CachedIngredient(from: $0) }
    }
}
