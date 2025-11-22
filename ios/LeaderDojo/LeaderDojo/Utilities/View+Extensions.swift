import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(LeaderDojoColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
