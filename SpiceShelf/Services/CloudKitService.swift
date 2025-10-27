import Foundation
import CloudKit

class CloudKitService: CloudKitServiceProtocol {
    
    private let container: CKContainer
    private let publicDB: CKDatabase
    
    init() {
        print("CloudKitService init")
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
    }
    
    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        let record = CKRecord(recordType: "Recipe", recordID: CKRecord.ID(recordName: recipe.id.uuidString))
        record["title"] = recipe.title
        record["ingredients"] = recipe.ingredients
        record["instructions"] = recipe.instructions
        record["sourceURL"] = recipe.sourceURL
        
        publicDB.save(record) { (savedRecord, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(recipe))
            }
        }
    }
    
    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        let query = CKQuery(recordType: "Recipe", predicate: NSPredicate(value: true))
        
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let recipes = records.compactMap { record -> Recipe? in
                guard let title = record["title"] as? String,
                      let ingredients = record["ingredients"] as? [String],
                      let instructions = record["instructions"] as? [String] else {
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
    
    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: recipe.id.uuidString)
        publicDB.fetch(withRecordID: recordID) { (record, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                // Handle error: record not found
                return
            }
            
            record["title"] = recipe.title
            record["ingredients"] = recipe.ingredients
            record["instructions"] = recipe.instructions
            record["sourceURL"] = recipe.sourceURL
            
            self.publicDB.save(record) { (savedRecord, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(recipe))
                }
            }
        }
    }
    
    func deleteRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: recipe.id.uuidString)
        publicDB.delete(withRecordID: recordID) { (deletedRecordID, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
