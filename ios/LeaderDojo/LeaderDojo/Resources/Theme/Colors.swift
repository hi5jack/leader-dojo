import SwiftUI

enum LeaderDojoColors {
    static let background = Color(UIColor.systemBackground)
    static let foreground = Color(UIColor.label)
    static let card = Color(UIColor.secondarySystemBackground)
    static let border = Color(UIColor.separator)
    static let primaryAction = Color(hex: "2D2D2D")
    static let primaryActionDark = Color(hex: "E8E8E8")
    static let amber = Color(hex: "F59E0B")
    static let blue = Color(hex: "3B82F6")
    static let red = Color(hex: "EF4444")
    static let green = Color(hex: "10B981")
    static let warning = Color(hex: "F97316")
    static let muted = Color(hex: "6B7280")
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
