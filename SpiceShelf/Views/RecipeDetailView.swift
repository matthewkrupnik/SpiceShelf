import SwiftUI
import CloudKit
import AVKit

struct RecipeDetailView: View {
    
    @StateObject private var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingEditView = false
    @State private var currentImageIndex = 0
    @State private var completedSteps: Set<UUID> = []
    
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
                    // Meta Info Bar (rating, cuisine, category, time)
                    RecipeMetaInfoBar(recipe: viewModel.recipe)
                    
                    // Description
                    if let description = viewModel.recipe.recipeDescription, !description.isEmpty {
                        Text(description)
                            .font(.sansBody())
                            .foregroundColor(.charcoal)
                            .padding(.bottom, 8)
                    }
                    
                    // Notes
                    if let notes = viewModel.recipe.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.serifHeading())
                                .foregroundColor(.sageGreen)
                            
                            Text(notes)
                                .font(.sansBody())
                                .foregroundColor(.charcoal)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.sageGreen.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.sageGreen.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Author & Source
                    if viewModel.recipe.author?.name != nil || viewModel.recipe.sourceURL != nil {
                        RecipeSourceView(recipe: viewModel.recipe)
                    }
                    
                    // Time Info
                    if viewModel.recipe.prepTime != nil || viewModel.recipe.cookTime != nil || viewModel.recipe.totalTime != nil {
                        RecipeTimeView(recipe: viewModel.recipe)
                    }
                    
                    // Dietary Info & Keywords
                    if let diets = viewModel.recipe.suitableForDiet, !diets.isEmpty {
                        DietaryBadgesView(diets: diets)
                    }
                    
                    if let keywords = viewModel.recipe.keywords, !keywords.isEmpty {
                        KeywordsView(keywords: keywords)
                    }
                    
                    // Controls - only show if servings is known
                    if viewModel.canScale {
                        HStack {
                            Spacer()
                            HStack(spacing: 0) {
                                Button(action: {
                                    if let current = viewModel.currentServings, current > 1 {
                                        viewModel.currentServings = current - 1
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.body.weight(.semibold))
                                        .frame(width: 44, height: 44)
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
                                        .font(.body.weight(.semibold))
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("Increase servings")
                                .accessibilityHint("Current servings: \(viewModel.currentServings ?? 0)")
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.regularMaterial)
                            .clipShape(Capsule())
                            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: viewModel.currentServings)
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
                                    .contentTransition(.symbolEffect(.replace))
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
                            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: viewModel.completedIngredients.count)
                            Divider().background(Color.subtleBorder)
                        }
                    }

                    // Instructions
                    InstructionsView(
                        recipe: viewModel.recipe,
                        completedSteps: $completedSteps
                    )
                    
                    // Video
                    if let video = viewModel.recipe.video {
                        RecipeVideoView(video: video)
                    }
                    
                    // Nutrition
                    if let nutrition = viewModel.recipe.nutrition {
                        NutritionView(nutrition: nutrition)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(20)
                .offset(y: -20) // Overlap effect
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .glassEffect()
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit", systemImage: "pencil") {
                    isShowingEditView = true
                }
                .glassEffect()
                
                Button("Delete", systemImage: "trash") {
                    viewModel.isShowingDeleteConfirmation = true
                }
                .glassEffect()
            }
        }
        .sheet(isPresented: $isShowingEditView) {
            EditRecipeView(viewModel: viewModel)
                .presentationBackground(.regularMaterial)
                .presentationCornerRadius(24)
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
