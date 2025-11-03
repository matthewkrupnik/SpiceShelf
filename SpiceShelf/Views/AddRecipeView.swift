import SwiftUI

struct AddRecipeView: View {
    @StateObject private var viewModel: AddRecipeViewModel
    @State private var title = ""
    @State private var ingredients: [Ingredient] = [Ingredient(id: UUID(), name: "", quantity: 1.0, units: "")]
    @State private var instructions: [String] = [""]
    @Environment(\.dismiss) private var dismiss

    // Allow injecting a view model (useful for tests); default will be created by the caller.
    init(viewModel: AddRecipeViewModel = AddRecipeViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipe Info")) {
                    TextField("Title", text: $title)
                }

                Section(header: Text("Ingredients")) {
                    ForEach($ingredients) { $ingredient in
                        HStack {
                            TextField("Name", text: $ingredient.name)
                            TextField("Quantity", value: $ingredient.quantity, format: .number)
                            TextField("Units", text: $ingredient.units)
                        }
                    }
                    Button("Add Ingredient") {
                        ingredients.append(Ingredient(id: UUID(), name: "", quantity: 1.0, units: ""))
                    }
                }

                Section(header: Text("Instructions")) {
                    ForEach(0..<instructions.count, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $instructions[index])
                    }
                    Button("Add Instruction") {
                        instructions.append("")
                    }
                }

                // Show the saved recipe title when available so UI tests can assert on it
                if let saved = viewModel.savedRecipe {
                    Section {
                        Text(saved.title)
                            .accessibilityIdentifier("SavedRecipeTitle")
                    }
                }
            }
            .navigationTitle("New Recipe")
            .navigationBarItems(trailing: Button("Save") {
                let nonEmptyIngredients = ingredients.filter { !$0.name.isEmpty }
                let nonEmptyInstructions = instructions.filter { !$0.isEmpty }
                viewModel.saveRecipe(title: title, ingredients: nonEmptyIngredients, instructions: nonEmptyInstructions)
            })
        }
        // Observe an Equatable value (the saved recipe's id) instead of the Recipe itself so we don't
        // need Recipe to conform to Equatable. UUID is Equatable so this satisfies onChange's requirement.
        .onChange(of: viewModel.savedRecipe?.id) { _ , newValue in
            if newValue != nil {
                // After a successful save, dismiss the sheet so UI tests can interact with the
                // underlying list and verify the new recipe appears.
                dismiss()
            }
        }
        .alert(isPresented: .constant(viewModel.error != nil), error: viewModel.error) {
            Button("OK") {
                viewModel.error = nil
            }
        }
    }
}
