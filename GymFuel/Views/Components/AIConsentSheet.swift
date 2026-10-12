import SwiftUI

/// Saves the agreement itself; the caller decides what happens once it closes.
struct AIConsentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AIConsent.preferenceKey) private var consentVersion = 0

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 20) {
                CircaSectionLabel("Before your first estimate")
                Text("Circa sends your meal to \(AIConsent.provider)")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text("To estimate a meal, Circa sends what you type, or your photo, to \(AIConsent.provider) through Circa's server. \(AIConsent.provider) works out the estimate and sends it back.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Only the meal is sent, not your name, email, weight or targets.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Link("Privacy Policy", destination: AppConfig.privacyPolicyURL)
                    .font(.circaRow)
                    .foregroundStyle(Color.circaAccent)

                Button {
                    consentVersion = AIConsent.version
                    dismiss()
                } label: {
                    Text("Agree and continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))

                Button("Not now") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.circa(.quiet))
            }
            .padding(Circa.Space.screenMargin)
        }
        .circaPaper()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text("Day")
        .sheet(isPresented: .constant(true)) { AIConsentSheet() }
}
