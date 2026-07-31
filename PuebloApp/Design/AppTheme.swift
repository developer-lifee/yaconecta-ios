import SwiftUI

enum AppTheme {
    static let coral = Color(red: 0.92, green: 0.29, blue: 0.20)
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.16)
    static let moss = Color(red: 0.18, green: 0.42, blue: 0.31)
    static let sand = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let sky = Color(red: 0.88, green: 0.94, blue: 0.96)
}

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.black.opacity(0.05), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}
