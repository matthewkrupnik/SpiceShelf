
import Foundation

struct Ingredient: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var quantity: Double
    var units: String
    
    // Original raw text from parsing (Schema.org stores ingredients as text)
    var rawText: String?
    
    init(id: UUID = UUID(), name: String, quantity: Double = 0, units: String = "", rawText: String? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.units = units
        self.rawText = rawText
    }
}
