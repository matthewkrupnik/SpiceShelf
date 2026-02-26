import XCTest
@testable import SpiceShelf

@MainActor
class RecipeDataStoreTests: XCTestCase {

    var store: RecipeDataStore!
    var mockCloudKitService: MockCloudKitService!

    override func setUpWithError() throws {
        mockCloudKitService = MockCloudKitService()
        store = RecipeDataStore(inMemory: true, cloudKitService: mockCloudKitService)
    }

    // MARK: - Save & Fetch

    func testSaveAndFetchRecipe() throws {
        let recipe = Recipe(id: UUID(),
                            title: "Pasta Carbonara",
                            ingredients: [Ingredient(name: "Spaghetti", quantity: 500, units: "g")],
                            instructions: ["Boil pasta", "Mix with sauce"],
                            sourceURL: nil)

        try store.saveRecipeLocally(recipe)
        let fetched = try store.fetchAllRecipes()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Pasta Carbonara")
        XCTAssertEqual(fetched.first?.ingredients.count, 1)
    }

    func testFetchCachedRecipeById() throws {
        let id = UUID()
        let recipe = Recipe(id: id,
                            title: "Test Recipe",
                            ingredients: [],
                            instructions: ["Step 1"],
                            sourceURL: nil)

        try store.saveRecipeLocally(recipe)
        let cached = try store.fetchCachedRecipe(byId: id)

        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.title, "Test Recipe")
    }

    func testFetchCachedRecipeByIdReturnsNilForUnknown() throws {
        let cached = try store.fetchCachedRecipe(byId: UUID())
        XCTAssertNil(cached)
    }

    // MARK: - Delete

    func testDeleteRecipeLocallyMarksPendingDelete() throws {
        let id = UUID()
        let recipe = Recipe(id: id,
                            title: "To Delete",
                            ingredients: [],
                            instructions: [],
                            sourceURL: nil)

        try store.saveRecipeLocally(recipe)
        try store.deleteRecipeLocally(recipe)

        let cached = try store.fetchCachedRecipe(byId: id)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.syncStatus, SyncStatus.pendingDelete.rawValue)
    }

    func testRemoveRecipeFromCache() throws {
        let id = UUID()
        let recipe = Recipe(id: id,
                            title: "Remove Me",
                            ingredients: [],
                            instructions: [],
                            sourceURL: nil)

        try store.saveRecipeLocally(recipe)
        try store.removeRecipeFromCache(recipe)

        let cached = try store.fetchCachedRecipe(byId: id)
        XCTAssertNil(cached)
    }

    // MARK: - Image Data

    func testSetAndGetImageData() throws {
        let id = UUID()
        let recipe = Recipe(id: id,
                            title: "Photo Recipe",
                            ingredients: [],
                            instructions: [],
                            sourceURL: nil)

        try store.saveRecipeLocally(recipe)
        let testData = Data([0x89, 0x50, 0x4E, 0x47])
        try store.setImageData(testData, for: id)

        let retrieved = store.imageData(for: id)
        XCTAssertEqual(retrieved, testData)
    }

    func testImageDataReturnsNilForUnknown() {
        let data = store.imageData(for: UUID())
        XCTAssertNil(data)
    }

    // MARK: - Multiple Recipes

    func testFetchReturnsMultipleRecipes() throws {
        for i in 1...3 {
            let recipe = Recipe(id: UUID(),
                                title: "Recipe \(i)",
                                ingredients: [],
                                instructions: [],
                                sourceURL: nil)
            try store.saveRecipeLocally(recipe)
        }

        let all = try store.fetchAllRecipes()
        XCTAssertEqual(all.count, 3)
    }

    func testSaveWithPendingUploadSyncStatus() throws {
        let recipe = Recipe(id: UUID(),
                            title: "Needs Sync",
                            ingredients: [],
                            instructions: [],
                            sourceURL: nil)

        try store.saveRecipeLocally(recipe, needsSync: true)
        let cached = try store.fetchCachedRecipe(byId: recipe.id)
        XCTAssertEqual(cached?.syncStatus, SyncStatus.pendingUpload.rawValue)
    }
}
