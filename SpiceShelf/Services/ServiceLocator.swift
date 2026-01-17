// ServiceLocator.swift
// Provides the correct CloudKit service depending on runtime (UI tests use mock)

import Foundation

enum ServiceLocator {
    // Lazily created shared mock service for UI tests. Non-UI runs will not create this.
    private static var _sharedMockCloudKitService: CloudKitServiceProtocol?

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

        return CloudKitService()
    }
}
