import SwiftUI

// MARK: - Colors

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
            ? UIColor(white: 0.0, alpha: 0.4)
            : UIColor(white: 0.0, alpha: 0.12)
    })
    
    static let secondaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.65, alpha: 1.0)
            : UIColor(white: 0.45, alpha: 1.0)
    })
}

// MARK: - Typography

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

// MARK: - Glass Card Modifier

extension View {
    /// Applies glass card styling with shadow
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .shadowColor, radius: 12, x: 0, y: 6)
    }
    
    /// Applies thin glass background for badges and pills
    func glassBadge() -> some View {
        self
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
    
    /// Applies ultra-thin glass for subtle backgrounds
    func glassSubtle(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Haptic Feedback

enum HapticStyle {
    case light, success, error
    
    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Time Formatting

extension Int {
    func formattedAsMinutes() -> String {
        let hours = self / 60
        let mins = self % 60
        if hours > 0 && mins > 0 {
            return "\(hours) hr \(mins) min"
        } else if hours > 0 {
            return "\(hours) hr"
        } else {
            return "\(mins) min"
        }
    }
}

// MARK: - Spacing Constants

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius Constants

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}


