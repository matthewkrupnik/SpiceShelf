import Foundation
import CloudKit

struct Recipe: Identifiable, Hashable, Codable {
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id: UUID
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]
    var sourceURL: String?
    var servings: Int?
    
    // CKAsset is not Codable, so we exclude it and handle separately
    var imageAsset: CKAsset? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, title, ingredients, instructions, sourceURL, servings
    }
}
