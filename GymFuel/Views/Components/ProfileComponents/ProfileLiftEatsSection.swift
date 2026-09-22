import SwiftUI

struct ProfileLiftEatsSection: View {
    let reviewURL: URL

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Circa")

            Link(destination: reviewURL) {
                ProfileSettingsRow(title: "Rate Circa", systemImage: "star", value: "App Store")
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal, Circa.Space.screenMargin)
    }
}
