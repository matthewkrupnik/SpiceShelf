import Foundation

struct Recipe: Identifiable {
    var id: UUID
    var title: String
    var ingredients: [String]
    var instructions: [String]
    var sourceURL: String?
}
