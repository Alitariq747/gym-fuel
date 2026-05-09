import SwiftUI

struct LogComposerBar: View {
    @Binding var text: String

    let focus: FocusState<Bool>.Binding
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

    private var isEmpty: Bool {
        trimmedText.isEmpty
    }

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 14) {
                TextField("What did you eat or exercise?", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .focused(focus)
                    .disabled(isSubmitting)
                    .onChange(of: text) { _, _ in
                        onClearError()
                    }
                    .onChange(of: isSubmitting) { _, newValue in
                        if newValue {
                            focus.wrappedValue = false
                        }
                    }

                if isEmpty {
                    HStack(spacing: 8) {
                        composerActionButton(systemName: "camera", action: onCameraTap)
                        composerActionButton(systemName: "photo", action: onPhotoTap)
                        composerActionButton(systemName: "bookmark", action: onSavedMealsTap)
                    }
                } else {
                    Button {
                        focus.wrappedValue = false
                        onSubmit()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(canSubmit ? Color.white : Color.secondary.opacity(0.9))
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(canSubmit ? Color.fuelBlue : Color(.tertiarySystemFill))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(canSubmit ? 0.24 : 0), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit || isSubmitting)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(isSubmitting ? Color(.systemGray6) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
            .opacity(isSubmitting ? 0.82 : 1)
        }
    }

    private func composerActionButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(.systemBackground).opacity(0.9))
                )
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var isFocused: Bool

    LogComposerBar(
        text: $text,
        focus: $isFocused,
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
