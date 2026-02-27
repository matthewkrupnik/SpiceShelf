import Foundation
import CloudKit

final class CloudKitService: CloudKitServiceProtocol, @unchecked Sendable {

    private let container: CKContainer
    private let privateDB: CKDatabase

    init() {
        print("CloudKitService init")
        container = CKContainer(identifier: "iCloud.mk.lan.SpiceShelf")
        privateDB = container.privateCloudDatabase
    }

    func saveRecipe(_ recipe: Recipe) async throws -> Recipe {
        let record = CKRecord(recordType: "Recipe", recordID: CKRecord.ID(recordName: recipe.id.uuidString))
        record["title"] = recipe.title
        if let ingredientsData = try? JSONEncoder().encode(recipe.ingredients) {
            record["ingredients"] = ingredientsData
        }
        record["instructions"] = recipe.instructions
        record["sourceURL"] = recipe.sourceURL
        record["notes"] = recipe.notes
        record["servings"] = recipe.servings
        if let imageAsset = recipe.imageAsset {
            record["imageAsset"] = imageAsset
        }

        return try await withCheckedThrowingContinuation { continuation in
            privateDB.save(record) { _, error in
                if let error = error {
                    if let ckError = error as? CKError {
                        print("CloudKit save error: code=\(ckError.code) description=\(ckError.localizedDescription) userInfo=\(ckError.userInfo)")
                    } else {
                        print("CloudKit save error: \(error.localizedDescription)")
                    }
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: recipe)
                }
            }
        }
    }

    func fetchRecipes() async throws -> [Recipe] {
        let query = CKQuery(recordType: "Recipe", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var fetchedRecords: [CKRecord] = []
        let operation = CKQueryOperation(query: query)

        return try await withCheckedThrowingContinuation { continuation in
            operation.recordMatchedBlock = { _, result in
                switch result {
                case .success(let record):
                    fetchedRecords.append(record)
                case .failure(let error):
                    print("CloudKit record matched error: \(error)")
                }
            }

            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    let recipes = fetchedRecords.compactMap { record -> Recipe? in
                        guard let title = record["title"] as? String,
                              let instructions = record["instructions"] as? [String] else {
                            return nil
                        }

                        var ingredients: [Ingredient]
                        if let ingredientsData = record["ingredients"] as? Data,
                           let decoded = try? JSONDecoder().decode([Ingredient].self, from: ingredientsData) {
                            ingredients = decoded
                        } else if let ingredientNames = record["ingredients"] as? [String] {
                            ingredients = ingredientNames.map { Ingredient(id: UUID(), name: $0, quantity: 0.0, units: "") }
                        } else {
                            return nil
                        }

                        let sourceURL = record["sourceURL"] as? String
                        let notes = record["notes"] as? String
                        let servings = record["servings"] as? Int ?? 4
                        let imageAsset = record["imageAsset"] as? CKAsset

                        return Recipe(id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                                      title: title,
                                      ingredients: ingredients,
                                      instructions: instructions,
                                      sourceURL: sourceURL,
                                      servings: servings,
                                      notes: notes,
                                      imageAsset: imageAsset)
                    }
                    continuation.resume(returning: recipes)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            operation.resultsLimit = CKQueryOperation.maximumResults
            privateDB.add(operation)
        }
    }

    func updateRecipe(_ recipe: Recipe) async throws -> Recipe {
        let recordID = CKRecord.ID(recordName: recipe.id.uuidString)

        return try await withCheckedThrowingContinuation { continuation in
            privateDB.fetch(withRecordID: recordID) { record, error in
                if let error = error {
                    if let ckError = error as? CKError {
                        print("CloudKit fetch for update error: code=\(ckError.code) description=\(ckError.localizedDescription) userInfo=\(ckError.userInfo)")
                    } else {
                        print("CloudKit fetch for update error: \(error.localizedDescription)")
                    }
                    continuation.resume(throwing: error)
                    return
                }

                guard let record = record else {
                    continuation.resume(throwing: NSError(domain: "CloudKitService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Record not found for recipe \(recipe.id)"]))
                    return
                }

                record["title"] = recipe.title
                if let ingredientsData = try? JSONEncoder().encode(recipe.ingredients) {
                    record["ingredients"] = ingredientsData
                }
                record["instructions"] = recipe.instructions
                record["sourceURL"] = recipe.sourceURL
                record["notes"] = recipe.notes
                record["servings"] = recipe.servings
                if let imageAsset = recipe.imageAsset {
                    record["imageAsset"] = imageAsset
                }

                self.privateDB.save(record) { _, error in
                    if let error = error {
                        if let ckError = error as? CKError {
                            print("CloudKit update save error: code=\(ckError.code) description=\(ckError.localizedDescription) userInfo=\(ckError.userInfo)")
                        } else {
                            print("CloudKit update save error: \(error.localizedDescription)")
                        }
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: recipe)
                    }
                }
            }
        }
    }

    func deleteRecipe(_ recipe: Recipe) async throws {
        let recordID = CKRecord.ID(recordName: recipe.id.uuidString)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            privateDB.delete(withRecordID: recordID) { _, error in
                if let error = error {
                    if let ckError = error as? CKError {
                        print("CloudKit delete error: code=\(ckError.code) description=\(ckError.localizedDescription) userInfo=\(ckError.userInfo)")
                    } else {
                        print("CloudKit delete error: \(error.localizedDescription)")
                    }
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
