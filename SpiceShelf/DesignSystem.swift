import SwiftUI

extension Color {
    static let spiceRed = Color("AccentColor")
    
    static let sageGreen = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.70, blue: 0.53, alpha: 1.0)
            : UIColor(red: 0.52, green: 0.60, blue: 0.47, alpha: 1.0)
    })
    
    static let terracotta = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.88, green: 0.50, blue: 0.40, alpha: 1.0)
            : UIColor(red: 0.80, green: 0.40, blue: 0.30, alpha: 1.0)
    })
    
    static let charcoal = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.91, alpha: 1.0)
            : UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
    })
    
    static let offWhite = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1.0)
    })
    
    static let cardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
            : UIColor.white
    })
    
    static let subtleFill = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.08)
            : UIColor(white: 0.0, alpha: 0.05)
    })
    
    static let subtleBorder = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.12)
            : UIColor(white: 0.0, alpha: 0.08)
    })
    
    static let shadowColor = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.0, alpha: 0.3)
            : UIColor(white: 0.0, alpha: 0.08)
    })
    
    static let secondaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.65, alpha: 1.0)
            : UIColor(white: 0.45, alpha: 1.0)
    })
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


