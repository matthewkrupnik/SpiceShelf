import SwiftUI
import CloudKit

struct RecipeDetailView: View {

    @StateObject var viewModel: RecipeDetailViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var isShowingEditView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image with Parallax
                GeometryReader { geometry in
                    let minY = geometry.frame(in: .global).minY
                    ZStack(alignment: .bottomLeading) {
                        if let imageAsset = viewModel.recipe.imageAsset,
                           let fileURL = imageAsset.fileURL,
                           let data = try? Data(contentsOf: fileURL),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height + (minY > 0 ? minY : 0))
                                .clipped()
                                .offset(y: (minY > 0 ? -minY : -minY)) // Sticky effect
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: geometry.size.width, height: geometry.size.height + (minY > 0 ? minY : 0))
                                .offset(y: (minY > 0 ? -minY : -minY)) // Sticky effect
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .offset(y: (minY > 0 ? -minY : -minY)) // Sticky effect
                        }

                        // Title Overlay
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 100)

                        Text(viewModel.recipe.title)
                            .font(.serifTitle())
                            .foregroundColor(.white)
                            .padding()
                            .shadow(radius: 4)
                            .offset(y: (minY > 0 ? -minY : -minY)) // Sticky effect
                    }
                }
                .frame(height: 300)

                VStack(alignment: .leading, spacing: 24) {
                    // Controls
                    HStack {
                        Spacer()
                        HStack {
                            Button(action: {
                                if viewModel.currentServings > 1 { viewModel.currentServings -= 1 }
                            }) {
                                Image(systemName: "minus")
                                    .padding(8)
                                    .background(Color.offWhite)
                                    .clipShape(Circle())
                            }

                            Text("\(viewModel.currentServings) Servings")
                                .font(.headline)
                                .frame(minWidth: 100)

                            Button(action: {
                                viewModel.currentServings += 1
                            }) {
                                Image(systemName: "plus")
                                    .padding(8)
                                    .background(Color.offWhite)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(25)
                        Spacer()
                    }
                    .padding(.top)

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.serifHeading())
                            .foregroundColor(.sageGreen)

                        ForEach(viewModel.scaledIngredients, id: \.id) { ingredient in
                            HStack {
                                Image(systemName: viewModel.completedIngredients.contains(ingredient.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.sageGreen)
                                    .font(.title3)

                                Text(
                                    "\(ingredient.quantity > 0 ? "\(String(format: "%g", ingredient.quantity))" : "")" +
                                    "\(ingredient.quantity > 0 ? " \(ingredient.units) " : "")" +
                                    "\(ingredient.name)"
                                )
                                .font(.sansBody())
                                .foregroundColor(viewModel.completedIngredients.contains(ingredient.id) ? .gray : .charcoal)
                                .strikethrough(viewModel.completedIngredients.contains(ingredient.id))

                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    if viewModel.completedIngredients.contains(ingredient.id) {
                                        viewModel.completedIngredients.remove(ingredient.id)
                                    } else {
                                        viewModel.completedIngredients.insert(ingredient.id)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            Divider().background(Color.gray.opacity(0.2))
                        }
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.serifHeading())
                            .foregroundColor(.sageGreen)

                        ForEach(viewModel.recipe.instructions.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 16) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Color.terracotta))

                                Text(viewModel.recipe.instructions[index])
                                    .font(.sansBody())
                                    .foregroundColor(.charcoal)
                                    .lineSpacing(4)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(20)
                .offset(y: -20) // Overlap effect
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(Color.offWhite)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            },
            trailing: HStack {
                Button(action: { viewModel.isShowingDeleteConfirmation = true }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                Button(action: { isShowingEditView = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
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
