import Foundation
import UIKit
import CloudKit

enum ValidationError: Error, LocalizedError {
    case emptyTitle

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return NSLocalizedString("The recipe title cannot be empty.", comment: "")
        }
    }
}


import Combine

@MainActor
class AddRecipeViewModel: ObservableObject {
    private let cloudKitService: CloudKitServiceProtocol

    // Published property so views can react when a recipe is saved
    @Published var savedRecipe: Recipe? = nil
    @Published var error: AlertError? = nil

    // Allow injecting a service (tests). If nil, use the ServiceLocator to pick the current service.
    init(cloudKitService: CloudKitServiceProtocol? = nil) {
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
    }

    func saveRecipe(title: String, ingredients: [Ingredient], instructions: [String], servings: Int? = nil, image: UIImage? = nil) {
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

        let recipe = Recipe(id: UUID(),
                              title: title,
                              ingredients: ingredients,
                              instructions: instructions,
                              sourceURL: nil,
                              servings: servings,
                              imageAsset: imageAsset)

        cloudKitService.saveRecipe(recipe) { (result: Result<Recipe, Error>) in
            switch result {
            case .success(let recipe):
                DispatchQueue.main.async {
                    self.savedRecipe = recipe
                    // Notify other parts of the app so they can refresh after a save
                    NotificationCenter.default.post(name: .recipeSaved, object: recipe)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.error = AlertError(underlyingError: error)
                }
            }
        }
    }
}
