import SwiftUI

struct ProfilePortionGuideSection: View {
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Portion Guide")

            Button(action: onOpen) {
                ProfileSettingsRow(
                    title: "See what amounts look like",
                    systemImage: "photo.on.rectangle.angled",
                    value: ""
                )
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal, Circa.Space.screenMargin)
    }
}
