import SwiftUI

struct TextEntrySheet: View {
    @Binding var text: String
    let onClearError: () -> Void
    let onAnalyze: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFocused: Bool

    private var canAnalyze: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            AdaptiveScrollContainer {
                VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.primary.opacity(0.82))
                            .frame(width: 48, height: 48)
                            .background(Color(.secondarySystemBackground), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 10)

                VStack(spacing: 22) {
                    Text("DESCRIBE YOUR MEAL OR WORKOUT")
                        .font(.system(size: 17, weight: .bold))
                        .tracking(0.2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.primary.opacity(0.88))

                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            VStack(spacing: 16) {
                                Text("e.g 200 grams of cooked chicken with one cup of boiled rice")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.primary.opacity(0.18))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)

                                Text("e.g Heavy leg day lasting more than 1 hour and 30 minutes.")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.primary.opacity(0.18))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 8)
                            .allowsHitTesting(false)
                        }

                        TextField("", text: $text, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 28, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(3...8)
                            .focused($isTextFocused)
                            .submitLabel(.done)
                            .onChange(of: text) { _, _ in
                                onClearError()
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 168, alignment: .top)
                    .padding(.horizontal, 12)

                    Spacer(minLength: 12)

                    Button {
                        isTextFocused = false
                        dismiss()
                        onAnalyze()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Interpret with AI")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundStyle(canAnalyze ? Color.white : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            canAnalyze ? Color.liftEatsCoral : Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAnalyze)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)

            }
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(34)
        .onAppear {
            isTextFocused = true
        }
    }
}

#Preview {
    TextEntrySheet(
        text: .constant(""),
        onClearError: {},
        onAnalyze: {}
    )
}
