import Foundation
import CloudKit

class CloudKitService: CloudKitServiceProtocol {

    private let container: CKContainer
    private let publicDB: CKDatabase

    init() {
        print("CloudKitService init")
        // Use explicit container identifier that matches the app's iCloud container entitlement
        // (this must also be present in the app's .entitlements and the developer portal)
        container = CKContainer(identifier: "iCloud.mk.lan.SpiceShelf")
        publicDB = container.publicCloudDatabase
    }

    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        let record = CKRecord(recordType: "Recipe", recordID: CKRecord.ID(recordName: recipe.id.uuidString))
        record["title"] = recipe.title
        // Encode ingredients as JSON Data so it's a CKRecordValue-compatible type
        if let ingredientsData = try? JSONEncoder().encode(recipe.ingredients) {
            record["ingredients"] = ingredientsData
        }
        record["instructions"] = recipe.instructions
        record["sourceURL"] = recipe.sourceURL

        publicDB.save(record) { (_, error) in
            DispatchQueue.main.async {
                if let error = error {
                    // Improved logging for debugging permission errors
                    if let ckError = error as? CKError {
                        print("CloudKit save error: code=\(ckError.code) description=\(ckError.localizedDescription) userInfo=\(ckError.userInfo)")
                    } else {
                        print("CloudKit save error: \(error.localizedDescription)")
                    }
                    completion(.failure(error))
                } else {
                    completion(.success(recipe))
                }
            }
        }
    }

    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        let query = CKQuery(recordType: "Recipe", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var fetchedRecords: [CKRecord] = []
        let operation = CKQueryOperation(query: query)

        if #available(iOS 15.0, *) {
            // Newer API surfaces per-record errors and a single query result.
            operation.recordMatchedBlock = { (_, result) in
                switch result {
                case .success(let record):
                    fetchedRecords.append(record)
                case .failure(let error):
                    // Log per-record errors but continue; callers can decide how to handle partial results
                    print("CloudKit record matched error: \(error)")
                }
            }

            operation.queryResultBlock = { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        let recipes = fetchedRecords.compactMap { record -> Recipe? in
                            guard let title = record["title"] as? String,
                                  let instructions = record["instructions"] as? [String] else {
                                return nil
                            }

                            // Try to decode ingredients stored as Data (JSON). If that fails, support legacy [String] storage.
                            var ingredients: [Ingredient]
                            if let ingredientsData = record["ingredients"] as? Data,
                               let decoded = try? JSONDecoder().decode([Ingredient].self, from: ingredientsData) {
                                ingredients = decoded
                            } else if let ingredientNames = record["ingredients"] as? [String] {
                                // Backwards-compat: convert string names to Ingredient objects with default quantity/units
                                ingredients = ingredientNames.map { Ingredient(id: UUID(), name: $0, quantity: 0.0, units: "") }
                            } else {
                                return nil
                            }

                            let sourceURL = record["sourceURL"] as? String

                            return Recipe(id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                                          title: title,
                                          ingredients: ingredients,
                                          instructions: instructions,
                                          sourceURL: sourceURL)
                        }

                        completion(.success(recipes))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        } else {
            // Fallback for older iOS versions
            operation.recordFetchedBlock = { record in
                fetchedRecords.append(record)
            }

            operation.queryCompletionBlock = { (cursor, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    let recipes = fetchedRecords.compactMap { record -> Recipe? in
                        guard let title = record["title"] as? String,
                              let instructions = record["instructions"] as? [String] else {
                            return nil
                        }

                        // Try to decode ingredients stored as Data (JSON). If that fails, support legacy [String] storage.
                        var ingredients: [Ingredient]
                        if let ingredientsData = record["ingredients"] as? Data,
                           let decoded = try? JSONDecoder().decode([Ingredient].self, from: ingredientsData) {
                            ingredients = decoded
                        } else if let ingredientNames = record["ingredients"] as? [String] {
                            // Backwards-compat: convert string names to Ingredient objects with default quantity/units
                            ingredients = ingredientNames.map { Ingredient(id: UUID(), name: $0, quantity: 0.0, units: "") }
                        } else {
                            return nil
                        }

                        let sourceURL = record["sourceURL"] as? String

                        return Recipe(id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                                      title: title,
                                      ingredients: ingredients,
                                      instructions: instructions,
                                      sourceURL: sourceURL)
                    }

                    completion(.success(recipes))
                }
            }
        }

        operation.resultsLimit = CKQueryOperation.maximumResults
        publicDB.add(operation)
    }

    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: recipe.id.uuidString)
        publicDB.fetch(withRecordID: recordID) { (record, error) in
            DispatchQueue.main.async {
                if let error = error {
                    if let ckError = error as? CKError {
                        print("CloudKit fetch for update error: code=\(ckError.code) description=\(ckError.localizedDescription) userInfo=\(ckError.userInfo)")
                    } else {
                        print("CloudKit fetch for update error: \(error.localizedDescription)")
                    }
                    completion(.failure(error))
                    return
                }

                guard let record = record else {
                    // Handle error: record not found
                    return
                }

                record["title"] = recipe.title
                // Encode ingredients as JSON Data so it's a CKRecordValue-compatible type
                if let ingredientsData = try? JSONEncoder().encode(recipe.ingredients) {
                    record["ingredients"] = ingredientsData
                }
                record["instructions"] = recipe.instructions
                record["sourceURL"] = recipe.sourceURL

                self.publicDB.save(record) { (_, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            if let ckError = error as? CKError {
                                print("CloudKit update save error: code=\(ckError.code) description=\(ckError.localizedDescription) userInfo=\(ckError.userInfo)")
                            } else {
                                print("CloudKit update save error: \(error.localizedDescription)")
                            }
                            completion(.failure(error))
                        } else {
                            completion(.success(recipe))
                        }
                    }
                }
            }
        }
    }

    func deleteRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: recipe.id.uuidString)
        publicDB.delete(withRecordID: recordID) { (_, error) in
            DispatchQueue.main.async {
                if let error = error {
                    if let ckError = error as? CKError {
                        print("CloudKit delete error: code=\(ckError.code) description=\(ckError.localizedDescription) userInfo=\(ckError.userInfo)")
                    } else {
                        print("CloudKit delete error: \(error.localizedDescription)")
                    }
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
