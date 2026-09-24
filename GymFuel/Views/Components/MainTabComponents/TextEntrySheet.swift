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
        VStack(spacing: 0) {
            header

            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 26) {
                    TextField(
                        "Your meal",
                        text: $text,
                        prompt: Text("e.g. a bowl of rice and chicken curry")
                            .foregroundStyle(Color.circaInk3),
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .font(.system(.title).weight(.medium))
                    .foregroundStyle(Color.circaInk)
                    .tint(Color.circaAccent)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3...)
                    .focused($isTextFocused)
                    .submitLabel(.done)
                    .accessibilityLabel("Describe your meal")
                    .onChange(of: text) { _, _ in onClearError() }

                    guidance
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            estimateButton
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 10)
                .padding(.bottom, 14)
        }
        .circaPaper()
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Circa.Radius.dock)
        .onAppear { isTextFocused = true }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            CircaSectionLabel("What did you eat?")
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: Circa.minHitTarget, alignment: .leading)

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(.body).weight(.medium))
                    .foregroundStyle(Color.circaInk2)
                    .frame(minWidth: Circa.minHitTarget, minHeight: Circa.minHitTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.leading, Circa.Space.screenMargin)
        .padding(.trailing, 12)
        .padding(.top, 24)
    }

    private var guidance: some View {
        VStack(alignment: .leading, spacing: 9) {
            CircaHairline()
                .padding(.bottom, 7)
            CircaSectionLabel("Say it how you'd say it to a person")
            Text("Quantities in whatever measure you actually use — rotis, katoris, a plate, half a bowl. How it was cooked helps most: ghee or oil, fried or dry.")
            Text("The more you say, the fewer assumptions Circa has to make.")
        }
        .font(.circaBody)
        .foregroundStyle(Color.circaInk2)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var estimateButton: some View {
        Button {
            isTextFocused = false
            dismiss()
            onAnalyze()
        } label: {
            Label("Estimate this", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.circa(.primary, height: 48))
        .disabled(!canAnalyze)
        .opacity(canAnalyze ? 1 : 0.45)
    }
}

private struct TextEntrySheetPreview: View {
    @State var text = ""

    var body: some View {
        TextEntrySheet(text: $text, onClearError: {}, onAnalyze: {})
    }
}

#Preview("Empty") {
    TextEntrySheetPreview()
}

#Preview("Filled · dark") {
    TextEntrySheetPreview(text: "two roti, chicken karahi, half a katori rice")
        .preferredColorScheme(.dark)
}

#Preview("AX3") {
    TextEntrySheetPreview(text: "A chicken wrap with mayonnaise, a side of fries and a cup of tea with milk.")
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("RTL") {
    TextEntrySheetPreview()
        .environment(\.layoutDirection, .rightToLeft)
}
