import SwiftUI

struct AppLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 18) {
            Text("LiftEats")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.circaInk)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.circaBarTrack)
                    .frame(width: 128, height: 4)

                Capsule()
                    .fill(Color.circaInk)
                    .frame(width: 46, height: 4)
                    .offset(x: isAnimating ? 82 : 0)
            }
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.circaPaper.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    AppLoadingView()
}
