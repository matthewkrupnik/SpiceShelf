import SwiftUI
import CloudKit

struct RecipeDetailView: View {
    
    @StateObject private var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingEditView = false
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image with Parallax
                GeometryReader { geometry in
                    let minY = geometry.frame(in: .global).minY
                    ZStack(alignment: .bottomLeading) {
                        CachedAsyncImage(asset: viewModel.recipe.imageAsset)
                            .frame(width: geometry.size.width, height: geometry.size.height + (minY > 0 ? minY : 0))
                            .clipped()
                            .offset(y: -minY)
                            .accessibilityHidden(true)

                        // Title Overlay
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 100)
                        .accessibilityHidden(true)

                        Text(viewModel.recipe.title)
                            .font(.serifTitle())
                            .foregroundColor(.white)
                            .padding()
                            .shadow(radius: 4)
                            .offset(y: -minY)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                .frame(height: 300)

                VStack(alignment: .leading, spacing: 24) {
                    // Controls - only show if servings is known
                    if viewModel.canScale {
                        HStack {
                            Spacer()
                            HStack {
                                Button(action: {
                                    if let current = viewModel.currentServings, current > 1 {
                                        viewModel.currentServings = current - 1
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .frame(width: 44, height: 44)
                                        .background(Color.offWhite)
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Decrease servings")
                                .accessibilityHint("Current servings: \(viewModel.currentServings ?? 0)")

                                Text("\(viewModel.currentServings ?? 0) Servings")
                                    .font(.headline)
                                    .frame(minWidth: 100)

                                Button(action: {
                                    if let current = viewModel.currentServings {
                                        viewModel.currentServings = current + 1
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .frame(width: 44, height: 44)
                                        .background(Color.offWhite)
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Increase servings")
                                .accessibilityHint("Current servings: \(viewModel.currentServings ?? 0)")
                            }
                            .padding(8)
                            .background(Color.subtleFill)
                            .cornerRadius(25)
                            Spacer()
                        }
                        .padding(.top)
                    }

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.serifHeading())
                            .foregroundColor(.sageGreen)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(viewModel.scaledIngredients, id: \.id) { ingredient in
                            let isCompleted = viewModel.completedIngredients.contains(ingredient.id)
                            let ingredientText = "\(ingredient.quantity > 0 ? "\(String(format: "%g", ingredient.quantity))" : "")" +
                                "\(ingredient.quantity > 0 ? " \(ingredient.units) " : "")" +
                                "\(ingredient.name)"
                            
                            HStack {
                                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.sageGreen)
                                    .font(.title3)
                                    .accessibilityHidden(true)

                                Text(ingredientText)
                                .font(.sansBody())
                                .foregroundColor(isCompleted ? .secondaryText : .charcoal)
                                .strikethrough(isCompleted)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    if isCompleted {
                                        viewModel.completedIngredients.remove(ingredient.id)
                                    } else {
                                        viewModel.completedIngredients.insert(ingredient.id)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(ingredientText)\(isCompleted ? ", completed" : "")")
                            .accessibilityHint("Double tap to \(isCompleted ? "mark as needed" : "mark as complete")")
                            .accessibilityAddTraits(.isButton)
                            Divider().background(Color.subtleBorder)
                        }
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.serifHeading())
                            .foregroundColor(.sageGreen)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(viewModel.recipe.instructions.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 16) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Color.terracotta))
                                    .accessibilityHidden(true)

                                Text(viewModel.recipe.instructions[index])
                                    .font(.sansBody())
                                    .foregroundColor(.charcoal)
                                    .lineSpacing(4)
                            }
                            .padding(.vertical, 8)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Step \(index + 1): \(viewModel.recipe.instructions[index])")
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", systemImage: "chevron.left") {
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Draw", systemImage: "pencil") {
                    isShowingEditView = true
                }
                
                Button("Erase", systemImage: "trash") {
                    viewModel.isShowingDeleteConfirmation = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditView) {
            EditRecipeView(viewModel: viewModel)
        }
        .alert(isPresented: $viewModel.isShowingDeleteConfirmation) {
            Alert(
                title: Text("Delete Recipe"),
                message: Text("Are you sure you want to delete this recipe?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteRecipe {
                        dismiss()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
        }
    }
}
