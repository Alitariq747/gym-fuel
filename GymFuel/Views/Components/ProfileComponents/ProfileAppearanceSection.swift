import SwiftUI

struct ProfileAppearanceSection: View {
    @Binding var colorSchemePreference: String

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Appearance", systemImage: "circle.lefthalf.filled")

            Menu {
                ForEach(AppColorSchemePreference.allCases) { preference in
                    Button {
                        colorSchemePreference = preference.rawValue
                    } label: {
                        Label(
                            preference.displayName,
                            systemImage: colorSchemePreference == preference.rawValue ? "checkmark" : ""
                        )
                    }
                }
            } label: {
                ProfileSettingsRow(
                    title: "Color Scheme",
                    systemImage: "paintbrush.fill",
                    value: selectedPreference.displayName,
                    tint: .fuelBlue
                )
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal)
    }

    private var selectedPreference: AppColorSchemePreference {
        AppColorSchemePreference(rawValue: colorSchemePreference) ?? .system
    }
}
