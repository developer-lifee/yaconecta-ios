import SwiftUI
import UIKit

enum AppTheme {
    static let coral = Color(red: 0.92, green: 0.29, blue: 0.20)
    
    static let ink = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.label
            : UIColor(red: 0.10, green: 0.14, blue: 0.16, alpha: 1.0)
    })
    
    static let moss = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.78, blue: 0.55, alpha: 1.0)
            : UIColor(red: 0.18, green: 0.42, blue: 0.31, alpha: 1.0)
    })
    
    static let sand = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.20, blue: 0.18, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1.0)
    })
    
    static let sky = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.24, blue: 0.34, alpha: 1.0)
            : UIColor(red: 0.88, green: 0.94, blue: 0.96, alpha: 1.0)
    })
}

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}
