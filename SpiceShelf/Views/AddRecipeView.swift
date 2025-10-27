import SwiftUI

struct AddRecipeView: View {
    @StateObject private var viewModel = AddRecipeViewModel()
    @State private var title = ""
    @State private var ingredients = ""
    @State private var instructions = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Ingredients", text: $ingredients)
                TextField("Instructions", text: $instructions)
            }
            .navigationTitle("New Recipe")
            .navigationBarItems(trailing: Button("Save") {
                viewModel.saveRecipe(title: title, ingredients: ingredients, instructions: instructions)
            })
        }
    }
}
