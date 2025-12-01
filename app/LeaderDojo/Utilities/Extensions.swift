import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Start of the current week
    var startOfWeek: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) ?? self
    }
    
    /// End of the current week
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }
    
    /// Start of the current month
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
    
    /// End of the current month
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }
    
    /// ISO week string (e.g., "2024-W45")
    var isoWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-'W'ww"
        return formatter.string(from: self)
    }
    
    /// ISO month string (e.g., "2024-11")
    var isoMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: self)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hide keyboard
    func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// MARK: - Color Extensions

extension Color {
    /// Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // App colors
    static let dojoOrange = Color(hex: "F97316")
    static let dojoBlue = Color(hex: "3B82F6")
    static let dojoPurple = Color(hex: "8B5CF6")
    static let dojoGreen = Color(hex: "22C55E")
    static let dojoRed = Color(hex: "EF4444")
}

// MARK: - String Extensions

extension String {
    /// Truncate string to specified length with ellipsis
    func truncated(to length: Int) -> String {
        if count <= length {
            return self
        }
        return String(prefix(length - 3)) + "..."
    }
    
    /// Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safe subscript that returns nil for out-of-bounds indices
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Optional Extensions

extension Optional where Wrapped == String {
    /// Returns true if nil or empty
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}




