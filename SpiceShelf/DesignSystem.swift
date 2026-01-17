import SwiftUI

extension Color {
    static let spiceRed = Color("AccentColor")
    static let sageGreen = Color(red: 0.52, green: 0.60, blue: 0.47)
    static let terracotta = Color(red: 0.8, green: 0.4, blue: 0.3) // New accent
    static let charcoal = Color(red: 0.15, green: 0.15, blue: 0.15) // Slightly darker
    static let offWhite = Color(red: 0.98, green: 0.98, blue: 0.97) // Warmer
    static let cardBackground = Color.white
}

extension Font {
    static func serifTitle() -> Font {
        return .system(size: 34, weight: .bold, design: .serif)
    }
    
    static func serifHeading() -> Font {
        return .system(size: 22, weight: .semibold, design: .serif)
    }
    
    static func sansBody() -> Font {
        return .system(size: 16, weight: .regular, design: .rounded)
    }
    
    static func sansCaption() -> Font {
        return .system(size: 14, weight: .medium, design: .rounded)
    }
}
