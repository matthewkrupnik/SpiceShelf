import Foundation
import CloudKit

enum CloudKitError: Error {
    case recordNotFound
}

class CloudKitService: CloudKitServiceProtocol {

    private enum RecordType {
        static let recipe = "Recipe"
    }

    private enum Field {
        static let title = "title"
        static let ingredients = "ingredients"
        static let instructions = "instructions"
        static let sourceURL = "sourceURL"
    }

    private let container: CKContainer
    private let publicDB: CKDatabase

    init() {
        print("CloudKitService init")
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
    }

    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        let record = CKRecord(recordType: RecordType.recipe, recordID: CKRecord.ID(recordName: recipe.id.uuidString))
        record[Field.title] = recipe.title
        record[Field.ingredients] = recipe.ingredients
        record[Field.instructions] = recipe.instructions
        record[Field.sourceURL] = recipe.sourceURL

        publicDB.save(record) { (_, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(recipe))
                }
            }
        }
    }

    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        // For a production app, it would be better to use CKQueryCursor to fetch recipes in batches
        // instead of all at once to improve performance with a large number of recipes.
        let query = CKQuery(recordType: RecordType.recipe, predicate: NSPredicate(value: true))

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
                        let recipes = fetchedRecords.compactMap(self.recipe)


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

                    let recipes = fetchedRecords.compactMap(self.recipe)

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
                    completion(.failure(error))
                    return
                }

                guard let record = record else {
                    completion(.failure(CloudKitError.recordNotFound))
                    return
                }

                record[Field.title] = recipe.title
                record[Field.ingredients] = recipe.ingredients
                record[Field.instructions] = recipe.instructions
                record[Field.sourceURL] = recipe.sourceURL

                self.publicDB.save(record) { (_, error) in
                    DispatchQueue.main.async {
                        if let error = error {
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
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    private func recipe(from record: CKRecord) -> Recipe? {
        guard let title = record[Field.title] as? String,
              let ingredients = record[Field.ingredients] as? [String],
              let instructions = record[Field.instructions] as? [String] else {
            return nil
        }

        let sourceURL = record[Field.sourceURL] as? String

        return Recipe(id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                      title: title,
                      ingredients: ingredients,
                      instructions: instructions,
                      sourceURL: sourceURL)
    }
}
