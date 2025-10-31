import SwiftUI

struct AddRecipeView: View {
    @StateObject private var viewModel: AddRecipeViewModel
    @State private var title = ""
    @State private var ingredients = ""
    @State private var instructions = ""
    @Environment(\.dismiss) private var dismiss

    // Allow injecting a view model (useful for tests); default will be created by the caller.
    init(viewModel: AddRecipeViewModel = AddRecipeViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Ingredients", text: $ingredients)
                TextField("Instructions", text: $instructions)

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
                viewModel.saveRecipe(title: title, ingredients: ingredients, instructions: instructions)
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
