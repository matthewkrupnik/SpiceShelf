import Foundation
import UIKit
import Combine
import CloudKit

@MainActor
class ImportRecipeViewModel: ObservableObject {
    enum State {
        case idle
        case importing
        case success
        case error
    }

    @Published var url: String = ""
    @Published var state: State = .idle
    @Published var error: AlertError? = nil

    private let cloudKitService: CloudKitServiceProtocol
    private let recipeParserService: RecipeParserServiceProtocol

    init(
        recipeParserService: RecipeParserServiceProtocol? = nil,
        cloudKitService: CloudKitServiceProtocol? = nil
    ) {
        self.recipeParserService = recipeParserService ?? RecipeParserService()
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
    }

    func importRecipe() {
        state = .importing
        error = nil

        guard let parseURL = URL(string: url) else {
            error = AlertError(underlyingError: URLError(.badURL))
            state = .error
            return
        }

        Task {
            do {
                var recipe = try await recipeParserService.parseRecipe(from: parseURL)
                if let imageAsset = await Self.downloadImageAsset(from: recipe.imageURL) {
                    recipe.imageAsset = imageAsset
                }
                let savedRecipe = try await cloudKitService.saveRecipe(recipe)
                self.state = .success
                NotificationCenter.default.post(name: .recipeSaved, object: savedRecipe)
            } catch {
                self.error = AlertError(underlyingError: error)
                self.state = .error
            }
        }
    }

    private static func downloadImageAsset(from urlString: String?) async -> CKAsset? {
        guard let urlString, let imageURL = URL(string: urlString) else { return nil }

        do {
            var request = URLRequest(url: imageURL)
            request.setValue(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
                forHTTPHeaderField: "User-Agent"
            )
            let (data, _) = try await URLSession.shared.data(for: request)
            guard UIImage(data: data) != nil else { return nil }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            try data.write(to: tempURL)
            return CKAsset(fileURL: tempURL)
        } catch {
            return nil
        }
    }
}
