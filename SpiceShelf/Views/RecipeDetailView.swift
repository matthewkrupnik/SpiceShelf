import SwiftUI

struct RecipeDetailView: View {
    
    @StateObject var viewModel: RecipeDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isShowingEditView = false
    
    var body: some View {
        Form {
            Section(header: Text(viewModel.recipe.title).font(.largeTitle).fontWeight(.bold)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.headline)
                    ForEach(viewModel.recipe.ingredients, id: \.self) { ingredient in
                        Text("- \(ingredient.quantity > 0 ? "\(ingredient.quantity) \(ingredient.units) of" : "") \(ingredient.name)")
                    }
                }
                .padding(.vertical)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions")
                        .font(.headline)
                    ForEach(viewModel.recipe.instructions.indices, id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .fontWeight(.bold)
                            Text(viewModel.recipe.instructions[index])
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        
        .navigationTitle(viewModel.recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .imageScale(.large)
            },
            trailing: HStack {
                Button(action: {
                    viewModel.isShowingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                Button(action: {
                    isShowingEditView = true
                }) {
                    Image(systemName: "pencil")
                }
            }
        )
        .sheet(isPresented: $isShowingEditView) {
            EditRecipeView(viewModel: viewModel)
        }
        .alert(isPresented: $viewModel.isShowingDeleteConfirmation) {
            Alert(
                title: Text("Delete Recipe"),
                message: Text("Are you sure you want to delete this recipe?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteRecipe {
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
