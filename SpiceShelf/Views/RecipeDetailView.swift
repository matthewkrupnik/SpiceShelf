import SwiftUI

struct RecipeDetailView: View {

    @StateObject var viewModel: RecipeDetailViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var isShowingEditView = false

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 16) {

                Text(viewModel.recipe.title)

                    .font(.largeTitle)

                    .fontWeight(.bold)

                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {

                    Text("Ingredients")

                        .font(.headline)

                        .padding(.horizontal)

                    ForEach(viewModel.recipe.ingredients, id: \.self) { ingredient in

                        // Use ingredient.name to avoid interpolating the Ingredient type directly
                        Text("- \(ingredient.name)")

                            .padding(.horizontal)

                    }

                }

                VStack(alignment: .leading, spacing: 8) {

                    Text("Instructions")

                        .font(.headline)

                        .padding(.horizontal)

                    ForEach(viewModel.recipe.instructions.indices, id: \.self) { index in

                        HStack(alignment: .top) {

                            Text("\(index + 1).")

                                .fontWeight(.bold)

                            Text(viewModel.recipe.instructions[index])

                        }

                        .padding(.horizontal)

                    }

                }

            }

        }

        .navigationTitle(viewModel.recipe.title)

        .navigationBarTitleDisplayMode(.inline)

                .navigationBarItems(
                    leading: Button(action: {
                        viewModel.isShowingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    },
                    trailing: Button("Edit") {
                        isShowingEditView = true
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
