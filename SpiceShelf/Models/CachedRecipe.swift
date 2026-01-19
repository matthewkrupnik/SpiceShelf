import Foundation
import SwiftData
import CloudKit

@Model
final class CachedIngredient {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: Double = 0
    var units: String = ""
    
    // Inverse relationship
    var recipe: CachedRecipe?
    
    init(id: UUID = UUID(), name: String = "", quantity: Double = 0, units: String = "") {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.units = units
    }
    
    convenience init(from ingredient: Ingredient) {
        self.init(id: ingredient.id, name: ingredient.name, quantity: ingredient.quantity, units: ingredient.units)
    }
    
    func toIngredient() -> Ingredient {
        Ingredient(id: id, name: name, quantity: quantity, units: units)
    }
}

@Model
final class CachedRecipe {
    var id: UUID = UUID()
    var title: String = ""
    @Relationship(deleteRule: .cascade, inverse: \CachedIngredient.recipe)
    var ingredients: [CachedIngredient]? = []
    var instructions: [String] = []
    var sourceURL: String?
    var servings: Int?
    var imageData: Data?
    
    // Sync tracking
    var lastModified: Date = Date()
    var needsSync: Bool = false
    var syncStatus: String = "synced" // "synced", "pendingUpload", "pendingDelete"
    
    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [CachedIngredient] = [],
        instructions: [String] = [],
        sourceURL: String? = nil,
        servings: Int? = nil,
        imageData: Data? = nil,
        lastModified: Date = Date(),
        needsSync: Bool = false,
        syncStatus: String = "synced"
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.sourceURL = sourceURL
        self.servings = servings
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
        
        self.init(
            id: recipe.id,
            title: recipe.title,
            ingredients: recipe.ingredients.map { CachedIngredient(from: $0) },
            instructions: recipe.instructions,
            sourceURL: recipe.sourceURL,
            servings: recipe.servings,
            imageData: imageData,
            lastModified: Date(),
            needsSync: false,
            syncStatus: "synced"
        )
    }
    
    func toRecipe() -> Recipe {
        Recipe(
            id: id,
            title: title,
            ingredients: (ingredients ?? []).map { $0.toIngredient() },
            instructions: instructions,
            sourceURL: sourceURL,
            servings: servings,
            imageAsset: nil // CKAsset will be handled by CloudKit service when syncing
        )
    }
    
    func update(from recipe: Recipe) {
        self.title = recipe.title
        self.instructions = recipe.instructions
        self.sourceURL = recipe.sourceURL
        self.servings = recipe.servings
        self.lastModified = Date()
        
        // Update image data if available
        if let asset = recipe.imageAsset,
           let url = asset.fileURL,
           let data = try? Data(contentsOf: url) {
            self.imageData = data
        }
        
        // Update ingredients
        self.ingredients?.removeAll()
        self.ingredients = recipe.ingredients.map { CachedIngredient(from: $0) }
    }
}
