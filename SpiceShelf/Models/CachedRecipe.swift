import Foundation
import SwiftData
import CloudKit

enum SyncStatus: String {
    case synced
    case pendingUpload
    case pendingDelete
}

@Model
final class CachedHowToStep {
    var id: UUID = UUID()
    var name: String?
    var text: String = ""
    var url: String?
    var image: String?
    var sortOrder: Int = 0
    
    // Inverse relationship
    var recipe: CachedRecipe?
    var section: CachedHowToSection?
    
    init(id: UUID = UUID(), name: String? = nil, text: String = "", url: String? = nil, image: String? = nil, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.text = text
        self.url = url
        self.image = image
        self.sortOrder = sortOrder
    }
    
    convenience init(from step: HowToStep, sortOrder: Int = 0) {
        self.init(id: step.id, name: step.name, text: step.text, url: step.url, image: step.image, sortOrder: sortOrder)
    }
    
    func toHowToStep() -> HowToStep {
        HowToStep(id: id, name: name, text: text, url: url, image: image)
    }
}

@Model
final class CachedHowToSection {
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \CachedHowToStep.section)
    var steps: [CachedHowToStep]? = []
    
    // Inverse relationship
    var recipe: CachedRecipe?
    
    init(id: UUID = UUID(), name: String = "", sortOrder: Int = 0, steps: [CachedHowToStep] = []) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.steps = steps
    }
    
    convenience init(from section: HowToSection, sortOrder: Int = 0) {
        let cachedSteps = section.steps.enumerated().map { CachedHowToStep(from: $0.element, sortOrder: $0.offset) }
        self.init(id: section.id, name: section.name, sortOrder: sortOrder, steps: cachedSteps)
    }
    
    func toHowToSection() -> HowToSection {
        let sortedSteps = (steps ?? []).sorted { $0.sortOrder < $1.sortOrder }
        return HowToSection(id: id, name: name, steps: sortedSteps.map { $0.toHowToStep() })
    }
}

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
    var images: [String]?
    var datePublished: Date?
    var keywords: [String]?
    
    // Recipe content
    @Relationship(deleteRule: .cascade, inverse: \CachedIngredient.recipe)
    var ingredients: [CachedIngredient]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \CachedHowToStep.recipe)
    var instructionSteps: [CachedHowToStep]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \CachedHowToSection.recipe)
    var instructionSections: [CachedHowToSection]? = []
    
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
    
    // Video (stored as JSON for flexibility)
    var videoJSON: String?
    
    // Source
    var sourceURL: String?
    
    // App-specific
    var notes: String?
    var imageData: Data?
    
    // Sync tracking
    var lastModified: Date = Date()
    var needsSync: Bool = false
    var syncStatus: String = SyncStatus.synced.rawValue
    
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
        images: [String]? = nil,
        datePublished: Date? = nil,
        keywords: [String]? = nil,
        ingredients: [CachedIngredient] = [],
        instructionSteps: [CachedHowToStep] = [],
        instructionSections: [CachedHowToSection] = [],
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
        videoJSON: String? = nil,
        sourceURL: String? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        lastModified: Date = Date(),
        needsSync: Bool = false,
        syncStatus: String = SyncStatus.synced.rawValue
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = recipeDescription
        self.authorName = authorName
        self.authorURL = authorURL
        self.images = images
        self.datePublished = datePublished
        self.keywords = keywords
        self.ingredients = ingredients
        self.instructionSteps = instructionSteps
        self.instructionSections = instructionSections
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
        self.videoJSON = videoJSON
        self.sourceURL = sourceURL
        self.notes = notes
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
        let nutritionJSON = RecipeJSONHelper.encodeNutrition(recipe.nutrition)
        
        // Encode video as JSON
        let videoJSON = RecipeJSONHelper.encodeVideo(recipe.video)
        
        // Convert instruction steps
        let cachedSteps = recipe.instructionSteps.enumerated().map { CachedHowToStep(from: $0.element, sortOrder: $0.offset) }
        
        // Convert instruction sections
        let cachedSections = (recipe.instructionSections ?? []).enumerated().map { CachedHowToSection(from: $0.element, sortOrder: $0.offset) }
        
        self.init(
            id: recipe.id,
            name: recipe.name,
            recipeDescription: recipe.recipeDescription,
            authorName: recipe.author?.name,
            authorURL: recipe.author?.url,
            images: recipe.images,
            datePublished: recipe.datePublished,
            keywords: recipe.keywords,
            ingredients: recipe.recipeIngredient.map { CachedIngredient(from: $0) },
            instructionSteps: cachedSteps,
            instructionSections: cachedSections,
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
            videoJSON: videoJSON,
            sourceURL: recipe.sourceURL,
            notes: recipe.notes,
            imageData: imageData,
            lastModified: Date(),
            needsSync: false,
            syncStatus: SyncStatus.synced.rawValue
        )
    }
    
    func toRecipe() -> Recipe {
        // Decode nutrition from JSON
        let nutrition = RecipeJSONHelper.decodeNutrition(nutritionJSON)
        
        // Decode video from JSON
        let video = RecipeJSONHelper.decodeVideo(videoJSON)
        
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
        
        // Convert instruction steps
        let sortedSteps = (instructionSteps ?? []).sorted { $0.sortOrder < $1.sortOrder }
        let steps = sortedSteps.map { $0.toHowToStep() }
        
        // Convert instruction sections
        let sortedSections = (instructionSections ?? []).sorted { $0.sortOrder < $1.sortOrder }
        let sections = sortedSections.isEmpty ? nil : sortedSections.map { $0.toHowToSection() }
        
        return Recipe(
            id: id,
            name: name,
            recipeDescription: recipeDescription,
            author: author,
            images: images,
            datePublished: datePublished,
            keywords: keywords,
            recipeIngredient: (ingredients ?? []).map { $0.toIngredient() },
            instructionSteps: steps,
            instructionSections: sections,
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
            video: video,
            sourceURL: sourceURL,
            notes: notes,
            imageAsset: Self.assetFromData(imageData, id: id)
        )
    }
    
    func update(from recipe: Recipe) {
        self.name = recipe.name
        self.recipeDescription = recipe.recipeDescription
        self.authorName = recipe.author?.name
        self.authorURL = recipe.author?.url
        self.images = recipe.images
        self.datePublished = recipe.datePublished
        self.keywords = recipe.keywords
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
        self.notes = recipe.notes
        self.lastModified = Date()
        
        // Update nutrition JSON
        self.nutritionJSON = RecipeJSONHelper.encodeNutrition(recipe.nutrition)
        
        // Update video JSON
        self.videoJSON = RecipeJSONHelper.encodeVideo(recipe.video)
        
        // Update image data if available
        if let asset = recipe.imageAsset,
           let url = asset.fileURL,
           let data = try? Data(contentsOf: url) {
            self.imageData = data
        }
        
        // Update ingredients
        self.ingredients?.removeAll()
        self.ingredients = recipe.recipeIngredient.map { CachedIngredient(from: $0) }
        
        // Update instruction steps
        self.instructionSteps?.removeAll()
        self.instructionSteps = recipe.instructionSteps.enumerated().map { CachedHowToStep(from: $0.element, sortOrder: $0.offset) }
        
        // Update instruction sections
        self.instructionSections?.removeAll()
        self.instructionSections = (recipe.instructionSections ?? []).enumerated().map { CachedHowToSection(from: $0.element, sortOrder: $0.offset) }
    }
    
    private static func assetFromData(_ data: Data?, id: UUID) -> CKAsset? {
        guard let data else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension("jpg")
        do {
            try data.write(to: url)
            return CKAsset(fileURL: url)
        } catch {
            return nil
        }
    }
}
