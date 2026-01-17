#if DEBUG
import Foundation

enum MockRecipes {
    static let recipes: [Recipe] = [
        Recipe(
            id: UUID(),
            title: "Recipe to be Edited",
            ingredients: [
                Ingredient(id: UUID(), name: "Ingredient 1", quantity: 1, units: "cup"),
                Ingredient(id: UUID(), name: "Ingredient 2", quantity: 2, units: "tbsp")
            ],
            instructions: ["Step 1", "Step 2"]
        ),
        Recipe(
            id: UUID(),
            title: "Recipe to be Deleted",
            ingredients: [
                Ingredient(id: UUID(), name: "Ingredient A", quantity: 3, units: "oz"),
                Ingredient(id: UUID(), name: "Ingredient B", quantity: 4, units: "grams")
            ],
            instructions: ["Step A", "Step B"]
        )
    ]
}
#endif
