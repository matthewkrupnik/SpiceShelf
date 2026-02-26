import SwiftUI
import AVKit

// MARK: - Shared Helpers

private func toggleStep(_ id: UUID, in steps: Binding<Set<UUID>>) {
    withAnimation(.spring()) {
        if steps.wrappedValue.contains(id) {
            steps.wrappedValue.remove(id)
        } else {
            steps.wrappedValue.insert(id)
        }
    }
}

// MARK: - Meta Info Bar (Rating, Cuisine, Category, Time)

struct RecipeMetaInfoBar: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Rating
                if let rating = recipe.aggregateRating {
                    RatingBadgeView(rating: rating)
                }
                
                // Total Time
                if let time = recipe.totalTime?.displayString {
                    MetaBadge(icon: "clock", text: time)
                }
                
                // Cuisine
                if let cuisine = recipe.recipeCuisine {
                    MetaBadge(icon: "globe", text: cuisine)
                }
                
                // Category
                if let category = recipe.recipeCategory {
                    MetaBadge(icon: "tag", text: category)
                }
                
                // Cooking Method
                if let method = recipe.cookingMethod {
                    MetaBadge(icon: "flame", text: method)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct MetaBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.sansCaption())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .foregroundColor(.charcoal)
        .clipShape(Capsule())
    }
}

struct RatingBadgeView: View {
    let rating: AggregateRating
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            if let value = rating.ratingValue {
                Text(String(format: "%.1f", value))
                    .font(.sansCaption())
                    .fontWeight(.semibold)
            }
            
            if let count = rating.ratingCount ?? rating.reviewCount {
                Text("(\(count))")
                    .font(.sansCaption())
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Source & Author

struct RecipeSourceView: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .foregroundColor(.sageGreen)
            
            VStack(alignment: .leading, spacing: 2) {
                if let authorName = recipe.author?.name {
                    Text("By \(authorName)")
                        .font(.sansCaption())
                        .foregroundColor(.charcoal)
                }
                
                if let sourceURL = recipe.sourceURL, let url = URL(string: sourceURL) {
                    Link(destination: url) {
                        Text(url.host ?? "View Source")
                            .font(.sansCaption())
                            .foregroundColor(.sageGreen)
                            .underline()
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Time Info

struct RecipeTimeView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time")
                .font(.serifHeading())
                .foregroundColor(.sageGreen)
                .accessibilityAddTraits(.isHeader)
            
            HStack(spacing: 20) {
                if let prep = recipe.prepTime?.displayString {
                    TimeCard(label: "Prep", time: prep, icon: "hands.sparkles")
                }
                
                if let cook = recipe.cookTime?.displayString {
                    TimeCard(label: "Cook", time: cook, icon: "flame")
                }
                
                if let total = recipe.totalTime?.displayString {
                    TimeCard(label: "Total", time: total, icon: "clock")
                }
            }
        }
    }
}

struct TimeCard: View {
    let label: String
    let time: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.terracotta)
            
            Text(time)
                .font(.sansBody())
                .fontWeight(.semibold)
                .foregroundColor(.charcoal)
            
            Text(label)
                .font(.sansCaption())
                .foregroundColor(.secondaryText)
        }
        .frame(minWidth: 70)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Dietary Badges

struct DietaryBadgesView: View {
    let diets: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dietary Info")
                .font(.serifHeading())
                .foregroundColor(.sageGreen)
                .accessibilityAddTraits(.isHeader)
            
            FlowLayout(spacing: 8) {
                ForEach(diets, id: \.self) { diet in
                    DietBadge(diet: diet)
                }
            }
        }
    }
}

struct DietBadge: View {
    let diet: String
    
    var displayName: String {
        // Convert Schema.org diet names to readable format
        diet
            .replacingOccurrences(of: "Diet", with: "")
            .replacingOccurrences(of: "https://schema.org/", with: "")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
    }
    
    var body: some View {
        Text(displayName)
            .font(.sansCaption())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.sageGreen.opacity(0.15))
            .foregroundColor(.sageGreen)
            .clipShape(Capsule())
    }
}

// MARK: - Keywords

struct KeywordsView: View {
    let keywords: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.serifHeading())
                .foregroundColor(.sageGreen)
                .accessibilityAddTraits(.isHeader)
            
            FlowLayout(spacing: 8) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.sansCaption())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.charcoal)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Instructions with Rich Steps

struct InstructionsView: View {
    let recipe: Recipe
    @Binding var completedSteps: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.serifHeading())
                .foregroundColor(.sageGreen)
                .accessibilityAddTraits(.isHeader)
            
            // Check if we have sections
            if let sections = recipe.instructionSections, !sections.isEmpty {
                ForEach(sections) { section in
                    SectionView(section: section, completedSteps: $completedSteps)
                }
            } else {
                // Flat list of steps
                ForEach(Array(recipe.instructionSteps.enumerated()), id: \.element.id) { index, step in
                    StepView(step: step, index: index + 1, isCompleted: completedSteps.contains(step.id)) {
                        toggleStep(step.id, in: $completedSteps)
                    }
                }
            }
        }
    }
}

struct SectionView: View {
    let section: HowToSection
    @Binding var completedSteps: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.name)
                .font(.headline)
                .foregroundColor(.terracotta)
                .padding(.top, 8)
            
            ForEach(Array(section.steps.enumerated()), id: \.element.id) { index, step in
                StepView(step: step, index: index + 1, isCompleted: completedSteps.contains(step.id)) {
                    toggleStep(step.id, in: $completedSteps)
                }
            }
        }
    }
}

struct StepView: View {
    let step: HowToStep
    let index: Int
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                // Step number with animated transition
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.sageGreen : Color.terracotta)
                        .frame(width: 30, height: 30)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .contentTransition(.symbolEffect(.replace))
                    } else {
                        Text("\(index)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.3), value: isCompleted)
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Step name (if available)
                    if let name = step.name, !name.isEmpty {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.charcoal)
                    }
                    
                    // Step text
                    Text(step.text)
                        .font(.sansBody())
                        .foregroundColor(isCompleted ? .secondaryText : .charcoal)
                        .strikethrough(isCompleted)
                        .lineSpacing(4)
                }
            }
            
            // Step image (if available)
            if let imageURL = step.image, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 150)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    case .failure:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding(.leading, 46)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(index)\(step.name.map { ": \($0)" } ?? ""): \(step.text)\(isCompleted ? ", completed" : "")")
        .accessibilityHint("Double tap to \(isCompleted ? "mark as incomplete" : "mark as complete")")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Video Player

struct RecipeVideoView: View {
    let video: RecipeVideo
    @State private var isShowingVideo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video")
                .font(.serifHeading())
                .foregroundColor(.sageGreen)
                .accessibilityAddTraits(.isHeader)
            
            Button(action: { isShowingVideo = true }) {
                ZStack {
                    // Thumbnail
                    if let thumbnailURL = video.thumbnailUrl?.first, let url = URL(string: thumbnailURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.subtleFill)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.subtleFill)
                            @unknown default:
                                Rectangle()
                                    .fill(Color.subtleFill)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.subtleFill)
                    }
                    
                    // Play button overlay
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    // Duration badge
                    if let duration = video.duration?.displayString {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(duration)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                    .padding(8)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .cornerRadius(12)
                .clipped()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Video title
            if let name = video.name {
                Text(name)
                    .font(.sansCaption())
                    .foregroundColor(.secondaryText)
            }
        }
        .sheet(isPresented: $isShowingVideo) {
            VideoPlayerSheet(video: video)
        }
    }
}

struct VideoPlayerSheet: View {
    let video: RecipeVideo
    @Environment(\.dismiss) private var dismiss
    
    var videoURL: URL? {
        if let contentUrl = video.contentUrl {
            return URL(string: contentUrl)
        } else if let embedUrl = video.embedUrl {
            return URL(string: embedUrl)
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let url = videoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                } else {
                    VStack {
                        Text("Video unavailable")
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .navigationTitle(video.name ?? "Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Nutrition Info

struct NutritionView: View {
    let nutrition: NutritionInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.serifHeading())
                .foregroundColor(.sageGreen)
                .accessibilityAddTraits(.isHeader)
            
            if let servingSize = nutrition.servingSize {
                Text("Per \(servingSize)")
                    .font(.sansCaption())
                    .foregroundColor(.secondaryText)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let calories = nutrition.calories {
                    NutritionItem(label: "Calories", value: calories, icon: "flame.fill")
                }
                if let protein = nutrition.proteinContent {
                    NutritionItem(label: "Protein", value: protein, icon: "p.circle")
                }
                if let carbs = nutrition.carbohydrateContent {
                    NutritionItem(label: "Carbs", value: carbs, icon: "c.circle")
                }
                if let fat = nutrition.fatContent {
                    NutritionItem(label: "Fat", value: fat, icon: "f.circle")
                }
                if let fiber = nutrition.fiberContent {
                    NutritionItem(label: "Fiber", value: fiber, icon: "leaf")
                }
                if let sugar = nutrition.sugarContent {
                    NutritionItem(label: "Sugar", value: sugar, icon: "cube")
                }
                if let sodium = nutrition.sodiumContent {
                    NutritionItem(label: "Sodium", value: sodium, icon: "drop")
                }
                if let cholesterol = nutrition.cholesterolContent {
                    NutritionItem(label: "Cholesterol", value: cholesterol, icon: "heart")
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct NutritionItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.terracotta)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.sansCaption())
                    .foregroundColor(.secondaryText)
                Text(value)
                    .font(.sansBody())
                    .fontWeight(.medium)
                    .foregroundColor(.charcoal)
            }
            
            Spacer()
        }
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
