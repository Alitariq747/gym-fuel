import SwiftUI

struct LogComposerBar: View {
    @Binding var text: String

    let isSubmitting: Bool
    let canSubmit: Bool
    let onClearError: () -> Void
    let onCameraTap: () -> Void
    let onPhotoTap: () -> Void
    let onSavedMealsTap: () -> Void
    let onSubmit: () -> Void

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField("What did you eat or exercise?", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground), in: Capsule())
                .disabled(isSubmitting)
                .onChange(of: text) { _, _ in
                    onClearError()
                }

            if isSubmitting {
                ProgressView()
                    .controlSize(.small)
            } else if trimmedText.isEmpty {
                HStack(spacing: 14) {
                    Button(action: onCameraTap) {
                        Image(systemName: "camera")
                    }

                    Button(action: onPhotoTap) {
                        Image(systemName: "photo")
                    }

                    Button(action: onSavedMealsTap) {
                        Image(systemName: "bookmark")
                    }
                }
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            } else {
                Button(action: onSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(canSubmit ? Color.fuelBlue : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
        }
    }
}

#Preview {
    @Previewable @State var text = ""

    LogComposerBar(
        text: $text,
        isSubmitting: false,
        canSubmit: false,
        onClearError: {},
        onCameraTap: {},
        onPhotoTap: {},
        onSavedMealsTap: {},
        onSubmit: {}
    )
    .padding()
}
