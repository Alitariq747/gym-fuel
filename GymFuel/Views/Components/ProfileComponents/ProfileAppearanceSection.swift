import SwiftUI

struct ProfileAppearanceSection: View {
    @Binding var colorSchemePreference: String

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Appearance")

            Menu {
                ForEach(AppColorSchemePreference.allCases) { preference in
                    Button {
                        colorSchemePreference = preference.rawValue
                    } label: {
                        if colorSchemePreference == preference.rawValue {
                            Label(preference.displayName, systemImage: "checkmark")
                        } else {
                            Text(preference.displayName)
                        }
                    }
                }
            } label: {
                ProfileSettingsRow(
                    title: "Color Scheme",
                    systemImage: "paintbrush.fill",
                    value: selectedPreference.displayName
                )
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal, Circa.Space.screenMargin)
    }

    private var selectedPreference: AppColorSchemePreference {
        AppColorSchemePreference(rawValue: colorSchemePreference) ?? .system
    }
}
