import SwiftUI

struct EditRecipeView: View {
    @ObservedObject var viewModel: RecipeDetailViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Recipe Title", text: $viewModel.recipe.title)
                }

                Section(header: Text("Ingredients")) {
                    ForEach($viewModel.recipe.ingredients) { $ingredient in
                        HStack {
                            TextField("Name", text: $ingredient.name)
                            TextField("Quantity", value: $ingredient.quantity, format: .number)
                            TextField("Units", text: $ingredient.units)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.recipe.ingredients.remove(atOffsets: offsets)
                    }
                    Button("Add Ingredient") {
                        viewModel.recipe.ingredients.append(Ingredient(id: UUID(), name: "", quantity: 1.0, units: ""))
                    }
                }

                Section(header: Text("Instructions")) {
                    ForEach(0..<viewModel.recipe.instructions.count, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $viewModel.recipe.instructions[index])
                    }
                    .onDelete { offsets in
                        viewModel.recipe.instructions.remove(atOffsets: offsets)
                    }
                    Button("Add Instruction") {
                        viewModel.recipe.instructions.append("")
                    }
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    viewModel.saveChanges()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
