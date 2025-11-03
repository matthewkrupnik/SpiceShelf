import Foundation

struct Recipe: Identifiable {
    var id: UUID
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]
    var sourceURL: String?
}
