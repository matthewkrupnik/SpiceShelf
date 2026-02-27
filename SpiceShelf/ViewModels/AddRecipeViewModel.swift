import Foundation
import UIKit
import CloudKit
import Combine

enum ValidationError: Error, LocalizedError {
    case emptyTitle

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return NSLocalizedString("The recipe title cannot be empty.", comment: "")
        }
    }
}

@MainActor
class AddRecipeViewModel: ObservableObject {
    private let cloudKitService: CloudKitServiceProtocol

    @Published var savedRecipe: Recipe? = nil
    @Published var error: AlertError? = nil

    init(cloudKitService: CloudKitServiceProtocol? = nil) {
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
    }

    func saveRecipe(
        title: String,
        ingredients: [Ingredient],
        instructionSteps: [HowToStep],
        instructionSections: [HowToSection]? = nil,
        servings: Int? = nil,
        image: UIImage? = nil,
        recipeDescription: String? = nil,
        recipeCuisine: String? = nil,
        recipeCategory: String? = nil,
        cookingMethod: String? = nil,
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        suitableForDiet: [String]? = nil,
        keywords: [String]? = nil,
        recipeYield: String? = nil,
        notes: String? = nil
    ) {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.error = AlertError(underlyingError: ValidationError.emptyTitle)
            return
        }

        var imageAsset: CKAsset? = nil
        if let image = image,
           let data = image.jpegData(compressionQuality: 0.8) {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = tempDir.appendingPathComponent(fileName)
            do {
                try data.write(to: fileURL)
                imageAsset = CKAsset(fileURL: fileURL)
            } catch {
                print("Error saving temp image: \(error)")
            }
        }
        
        // Calculate total time
        var totalTime: RecipeDuration? = nil
        if let prep = prepTimeMinutes, let cook = cookTimeMinutes {
            totalTime = RecipeDuration(minutes: prep + cook)
        } else if let prep = prepTimeMinutes {
            totalTime = RecipeDuration(minutes: prep)
        } else if let cook = cookTimeMinutes {
            totalTime = RecipeDuration(minutes: cook)
        }
        
        // Filter out empty steps
        let nonEmptySteps = instructionSteps.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Filter out empty sections and steps within sections
        let nonEmptySections: [HowToSection]? = instructionSections?.compactMap { section in
            let filteredSteps = section.steps.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            guard !filteredSteps.isEmpty || !section.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return HowToSection(id: section.id, name: section.name, steps: filteredSteps)
        }.nilIfEmpty

        let recipe = Recipe(
            id: UUID(),
            name: title,
            recipeDescription: recipeDescription?.isEmpty == true ? nil : recipeDescription,
            keywords: keywords,
            recipeIngredient: ingredients,
            instructionSteps: nonEmptySteps,
            instructionSections: nonEmptySections,
            recipeYield: recipeYield ?? servings.map { "\($0) servings" },
            servings: servings,
            recipeCategory: recipeCategory?.isEmpty == true ? nil : recipeCategory,
            recipeCuisine: recipeCuisine?.isEmpty == true ? nil : recipeCuisine,
            cookingMethod: cookingMethod?.isEmpty == true ? nil : cookingMethod,
            suitableForDiet: suitableForDiet?.isEmpty == true ? nil : suitableForDiet,
            prepTime: prepTimeMinutes.map { RecipeDuration(minutes: $0) },
            cookTime: cookTimeMinutes.map { RecipeDuration(minutes: $0) },
            totalTime: totalTime,
            notes: notes?.isEmpty == true ? nil : notes,
            imageAsset: imageAsset
        )

        Task {
            do {
                let savedRecipe = try await cloudKitService.saveRecipe(recipe)
                self.savedRecipe = savedRecipe
                NotificationCenter.default.post(name: .recipeSaved, object: savedRecipe)
            } catch {
                self.error = AlertError(underlyingError: error)
            }
        }
    }
}

// MARK: - Array Extension

private extension Array {
    var nilIfEmpty: [Element]? {
        isEmpty ? nil : self
    }
}
