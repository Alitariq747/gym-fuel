import SwiftUI

struct ProfileSavedMealsSection: View {
    let savedMealCount: Int
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Saved Meals")

            Button(action: onOpen) {
                ProfileSettingsRow(
                    title: "Manage saved meals",
                    systemImage: "fork.knife",
                    value: "\(savedMealCount)"
                )
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal, Circa.Space.screenMargin)
    }
}
