
import Foundation

struct Ingredient: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var quantity: Double
    var units: String
}
