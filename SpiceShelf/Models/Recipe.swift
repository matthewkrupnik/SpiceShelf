import Foundation
import CloudKit

// MARK: - Schema.org Recipe Model
// Based on https://schema.org/Recipe specification

// MARK: - JSON Encoding Helpers (for SwiftData @Model compatibility)
// These use manual encoding to avoid MainActor isolation issues with synthesized Codable

enum RecipeJSONHelper {
    static func encodeNutrition(_ nutrition: NutritionInfo?) -> String? {
        guard let nutrition = nutrition else { return nil }
        var dict: [String: String] = [:]
        if let v = nutrition.calories { dict["calories"] = v }
        if let v = nutrition.fatContent { dict["fatContent"] = v }
        if let v = nutrition.saturatedFatContent { dict["saturatedFatContent"] = v }
        if let v = nutrition.cholesterolContent { dict["cholesterolContent"] = v }
        if let v = nutrition.sodiumContent { dict["sodiumContent"] = v }
        if let v = nutrition.carbohydrateContent { dict["carbohydrateContent"] = v }
        if let v = nutrition.fiberContent { dict["fiberContent"] = v }
        if let v = nutrition.sugarContent { dict["sugarContent"] = v }
        if let v = nutrition.proteinContent { dict["proteinContent"] = v }
        if let v = nutrition.servingSize { dict["servingSize"] = v }
        guard !dict.isEmpty, let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func decodeNutrition(_ json: String?) -> NutritionInfo? {
        guard let json = json, let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return nil }
        return NutritionInfo(
            calories: dict["calories"],
            fatContent: dict["fatContent"],
            saturatedFatContent: dict["saturatedFatContent"],
            cholesterolContent: dict["cholesterolContent"],
            sodiumContent: dict["sodiumContent"],
            carbohydrateContent: dict["carbohydrateContent"],
            fiberContent: dict["fiberContent"],
            sugarContent: dict["sugarContent"],
            proteinContent: dict["proteinContent"],
            servingSize: dict["servingSize"]
        )
    }
    
    static func encodeVideo(_ video: RecipeVideo?) -> String? {
        guard let video = video else { return nil }
        var dict: [String: Any] = [:]
        if let v = video.name { dict["name"] = v }
        if let v = video.videoDescription { dict["description"] = v }
        if let v = video.thumbnailUrl { dict["thumbnailUrl"] = v }
        if let v = video.contentUrl { dict["contentUrl"] = v }
        if let v = video.embedUrl { dict["embedUrl"] = v }
        if let v = video.uploadDate { dict["uploadDate"] = ISO8601DateFormatter().string(from: v) }
        if let v = video.duration?.iso8601 { dict["duration"] = v }
        guard !dict.isEmpty, let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func decodeVideo(_ json: String?) -> RecipeVideo? {
        guard let json = json, let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        var uploadDate: Date? = nil
        if let dateStr = dict["uploadDate"] as? String {
            uploadDate = ISO8601DateFormatter().date(from: dateStr)
        }
        var duration: RecipeDuration? = nil
        if let durationStr = dict["duration"] as? String {
            duration = RecipeDuration.fromISO8601(durationStr)
        }
        return RecipeVideo(
            name: dict["name"] as? String,
            videoDescription: dict["description"] as? String,
            thumbnailUrl: dict["thumbnailUrl"] as? [String],
            contentUrl: dict["contentUrl"] as? String,
            embedUrl: dict["embedUrl"] as? String,
            uploadDate: uploadDate,
            duration: duration
        )
    }
}

/// Nutrition information for a recipe (Schema.org NutritionInformation)
struct NutritionInfo: Codable, Hashable, Sendable {
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
struct RecipeDuration: Codable, Hashable, Sendable {
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

/// A single step in recipe instructions (Schema.org HowToStep)
struct HowToStep: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String?           // Optional step title (e.g., "Preheat")
    var text: String            // The instruction text
    var url: String?            // URL to this step (e.g., "https://example.com/recipe#step1")
    var image: String?          // Image URL for this step
    
    init(id: UUID = UUID(), name: String? = nil, text: String, url: String? = nil, image: String? = nil) {
        self.id = id
        self.name = name
        self.text = text
        self.url = url
        self.image = image
    }
    
    /// Convenience initializer from plain text
    init(_ text: String) {
        self.id = UUID()
        self.name = nil
        self.text = text
        self.url = nil
        self.image = nil
    }
}

/// A section of steps in recipe instructions (Schema.org HowToSection)
struct HowToSection: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String            // Section title (e.g., "Prepare the dough")
    var steps: [HowToStep]      // Steps in this section
    
    init(id: UUID = UUID(), name: String, steps: [HowToStep] = []) {
        self.id = id
        self.name = name
        self.steps = steps
    }
}

/// Video information for a recipe (Schema.org VideoObject)
struct RecipeVideo: Codable, Hashable, Sendable {
    var name: String?                   // Video title
    var videoDescription: String?       // Video description
    var thumbnailUrl: [String]?         // Thumbnail images (multiple aspect ratios)
    var contentUrl: String?             // Direct URL to video file
    var embedUrl: String?               // Embeddable player URL
    var uploadDate: Date?               // When video was uploaded
    var duration: RecipeDuration?       // Video length
    
    enum CodingKeys: String, CodingKey {
        case name, thumbnailUrl, contentUrl, embedUrl, uploadDate, duration
        case videoDescription = "description"
    }
}

/// Author/creator information (Schema.org Person or Organization)
struct RecipeAuthor: Codable, Hashable, Sendable {
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
    
    /// URLs of images (Schema.org: image) - supports multiple aspect ratios
    var images: [String]?
    
    /// Primary image URL (first from images array, for convenience)
    var imageURL: String? {
        get { images?.first }
        set {
            if let url = newValue {
                images = [url]
            } else {
                images = nil
            }
        }
    }
    
    /// Date published (Schema.org: datePublished)
    var datePublished: Date?
    
    /// Keywords/tags (Schema.org: keywords)
    var keywords: [String]?
    
    // MARK: - Recipe-Specific Properties
    
    /// List of ingredients (Schema.org: recipeIngredient)
    var recipeIngredient: [Ingredient]
    
    /// Step-by-step instructions as rich HowToStep objects (Schema.org: recipeInstructions)
    var instructionSteps: [HowToStep]
    
    /// Instruction sections for complex recipes (Schema.org: HowToSection)
    var instructionSections: [HowToSection]?
    
    /// Plain text instructions (computed from instructionSteps for backward compatibility)
    var recipeInstructions: [String] {
        get { instructionSteps.map { $0.text } }
        set { instructionSteps = newValue.map { HowToStep($0) } }
    }
    
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
    
    // MARK: - Media
    
    /// Video showing how to make the recipe (Schema.org: video)
    var video: RecipeVideo?
    
    // MARK: - Source & Metadata
    
    /// Source URL where recipe was imported from (Schema.org: url)
    var sourceURL: String?
    
    // MARK: - App-Specific (not in Schema.org)
    
    /// Personal notes about the recipe
    var notes: String?
    
    /// CloudKit image asset (not codable, handled separately)
    var imageAsset: CKAsset? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, name, recipeDescription, author, images, datePublished, keywords
        case recipeIngredient, instructionSteps, instructionSections, recipeYield, servings
        case recipeCategory, recipeCuisine, cookingMethod, suitableForDiet
        case prepTime, cookTime, totalTime
        case nutrition, aggregateRating, video, sourceURL, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        recipeDescription = try container.decodeIfPresent(String.self, forKey: .recipeDescription)
        author = try container.decodeIfPresent(RecipeAuthor.self, forKey: .author)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        datePublished = try container.decodeIfPresent(Date.self, forKey: .datePublished)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
        recipeIngredient = try container.decode([Ingredient].self, forKey: .recipeIngredient)
        instructionSteps = try container.decode([HowToStep].self, forKey: .instructionSteps)
        instructionSections = try container.decodeIfPresent([HowToSection].self, forKey: .instructionSections)
        recipeYield = try container.decodeIfPresent(String.self, forKey: .recipeYield)
        servings = try container.decodeIfPresent(Int.self, forKey: .servings)
        recipeCategory = try container.decodeIfPresent(String.self, forKey: .recipeCategory)
        recipeCuisine = try container.decodeIfPresent(String.self, forKey: .recipeCuisine)
        cookingMethod = try container.decodeIfPresent(String.self, forKey: .cookingMethod)
        suitableForDiet = try container.decodeIfPresent([String].self, forKey: .suitableForDiet)
        prepTime = try container.decodeIfPresent(RecipeDuration.self, forKey: .prepTime)
        cookTime = try container.decodeIfPresent(RecipeDuration.self, forKey: .cookTime)
        totalTime = try container.decodeIfPresent(RecipeDuration.self, forKey: .totalTime)
        nutrition = try container.decodeIfPresent(NutritionInfo.self, forKey: .nutrition)
        aggregateRating = try container.decodeIfPresent(AggregateRating.self, forKey: .aggregateRating)
        video = try container.decodeIfPresent(RecipeVideo.self, forKey: .video)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        imageAsset = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(recipeDescription, forKey: .recipeDescription)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(datePublished, forKey: .datePublished)
        try container.encodeIfPresent(keywords, forKey: .keywords)
        try container.encode(recipeIngredient, forKey: .recipeIngredient)
        try container.encode(instructionSteps, forKey: .instructionSteps)
        try container.encodeIfPresent(instructionSections, forKey: .instructionSections)
        try container.encodeIfPresent(recipeYield, forKey: .recipeYield)
        try container.encodeIfPresent(servings, forKey: .servings)
        try container.encodeIfPresent(recipeCategory, forKey: .recipeCategory)
        try container.encodeIfPresent(recipeCuisine, forKey: .recipeCuisine)
        try container.encodeIfPresent(cookingMethod, forKey: .cookingMethod)
        try container.encodeIfPresent(suitableForDiet, forKey: .suitableForDiet)
        try container.encodeIfPresent(prepTime, forKey: .prepTime)
        try container.encodeIfPresent(cookTime, forKey: .cookTime)
        try container.encodeIfPresent(totalTime, forKey: .totalTime)
        try container.encodeIfPresent(nutrition, forKey: .nutrition)
        try container.encodeIfPresent(aggregateRating, forKey: .aggregateRating)
        try container.encodeIfPresent(video, forKey: .video)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try container.encodeIfPresent(notes, forKey: .notes)
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
    
    /// All steps flattened (from both instructionSteps and instructionSections)
    var allSteps: [HowToStep] {
        var steps = instructionSteps
        if let sections = instructionSections {
            for section in sections {
                steps.append(contentsOf: section.steps)
            }
        }
        return steps
    }
    
    // MARK: - Initializers
    
    /// Full initializer with all Schema.org properties
    init(
        id: UUID = UUID(),
        name: String,
        recipeDescription: String? = nil,
        author: RecipeAuthor? = nil,
        images: [String]? = nil,
        datePublished: Date? = nil,
        keywords: [String]? = nil,
        recipeIngredient: [Ingredient] = [],
        instructionSteps: [HowToStep] = [],
        instructionSections: [HowToSection]? = nil,
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
        video: RecipeVideo? = nil,
        sourceURL: String? = nil,
        notes: String? = nil,
        imageAsset: CKAsset? = nil
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = recipeDescription
        self.author = author
        self.images = images
        self.datePublished = datePublished
        self.keywords = keywords
        self.recipeIngredient = recipeIngredient
        self.instructionSteps = instructionSteps
        self.instructionSections = instructionSections
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
        self.video = video
        self.sourceURL = sourceURL
        self.notes = notes
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
        notes: String? = nil,
        imageAsset: CKAsset? = nil
    ) {
        self.id = id
        self.name = title
        self.recipeIngredient = ingredients
        self.instructionSteps = instructions.map { HowToStep($0) }
        self.sourceURL = sourceURL
        self.servings = servings
        self.notes = notes
        self.imageAsset = imageAsset
        
        // Initialize other properties to nil
        self.recipeDescription = nil
        self.author = nil
        self.images = nil
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
        self.instructionSections = nil
        self.video = nil
    }
}
