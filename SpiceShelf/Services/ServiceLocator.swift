// ServiceLocator.swift
// Provides the correct CloudKit service depending on runtime (UI tests use mock)

import Foundation

enum ServiceLocator {
    // Lazily created shared mock service for UI tests. Non-UI runs will not create this.
    private static var _sharedMockCloudKitService: CloudKitServiceProtocol?
    
    // Lazily created offline-first service for production use
    @MainActor
    private static var _sharedOfflineFirstService: OfflineFirstRecipeService?

    @MainActor
    static func currentCloudKitService() -> CloudKitServiceProtocol {
        if ProcessInfo.processInfo.arguments.contains("UITestUseMockCloudKit") {
            if let mock = _sharedMockCloudKitService {
                return mock
            } else {
                let initialRecipes = ProcessInfo.processInfo.arguments.contains("UITestWithMockRecipes") ? MockRecipes.recipes : []
                let mock = MockCloudKitService(initialRecipes: initialRecipes)
                _sharedMockCloudKitService = mock
                return mock
            }
        }

        // Use offline-first service for production
        if let service = _sharedOfflineFirstService {
            return service
        }
        
        let service = OfflineFirstRecipeService()
        _sharedOfflineFirstService = service
        return service
    }
    
    /// Returns the raw CloudKit service (bypasses offline-first caching)
    static func rawCloudKitService() -> CloudKitServiceProtocol {
        return CloudKitService()
    }
}
