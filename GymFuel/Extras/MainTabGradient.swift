import SwiftUI

struct MainTabGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemGray5),
                Color(.systemGray6),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("Main Tab Gradient") {
    ZStack {
        MainTabGradientBackground()
            .ignoresSafeArea()

        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .frame(height: 110)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .frame(height: 110)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)

            Spacer()
        }
        .padding(20)
    }
}

