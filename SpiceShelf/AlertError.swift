import Foundation

struct AlertError: LocalizedError {
    let underlyingError: Error

    var errorDescription: String? {
        underlyingError.localizedDescription
    }
}
