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
                    // Bind the ingredients array to a multi-line text editor by mapping Ingredient -> name and back.
                    TextEditor(text: Binding(
                        get: {
                            // Join ingredient names into newline-separated text
                            viewModel.recipe.ingredients.map { $0.name }.joined(separator: "\n")
                        },
                        set: { newValue in
                            // Split lines, trim, ignore empty lines
                            let names = newValue
                                .components(separatedBy: "\n")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }

                            // Preserve existing ingredient ids/quantities where possible
                            var updated: [Ingredient] = []
                            for (index, name) in names.enumerated() {
                                if index < viewModel.recipe.ingredients.count {
                                    var existing = viewModel.recipe.ingredients[index]
                                    existing.name = name
                                    updated.append(existing)
                                } else {
                                    updated.append(Ingredient(id: UUID(), name: name, quantity: 0.0, units: ""))
                                }
                            }

                            viewModel.recipe.ingredients = updated
                        }
                    ))
                }
                Section(header: Text("Instructions")) {
                    TextEditor(text: Binding(
                        get: { viewModel.recipe.instructions.joined(separator: "\n") },
                        set: { viewModel.recipe.instructions = $0.components(separatedBy: "\n") }
                    ))
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
