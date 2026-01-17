import Foundation
import CloudKit

struct Recipe: Identifiable {
    var id: UUID
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]
    var sourceURL: String?
    var servings: Int = 4
    var imageAsset: CKAsset? = nil
}
