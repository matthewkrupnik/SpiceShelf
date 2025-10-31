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
                    TextEditor(text: Binding(
                        get: { viewModel.recipe.ingredients.joined(separator: "\n") },
                        set: { viewModel.recipe.ingredients = $0.components(separatedBy: "\n") }
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
