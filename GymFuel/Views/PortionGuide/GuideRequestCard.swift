//
//  GuideRequestCard.swift
//  GymFuel
//

import SwiftUI

struct GuideRequestCard: View {
    let userId: String

    @StateObject private var model = GuideRequestViewModel()
    @FocusState private var isFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // Side by side, a large Send squeezes the field (design.md rule 8).
        let fieldRow = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 12))

        VStack(alignment: .leading, spacing: 10) {
            CircaSectionLabel("Missing a food?")
            CircaFieldCard(isFocused: $isFocused) {
                VStack(alignment: .leading, spacing: 8) {
                    fieldRow {
                        TextField(
                            "Food",
                            text: $model.text,
                            prompt: Text("e.g. sweet potato").foregroundStyle(Color.circaInk3)
                        )
                        .textFieldStyle(.plain)
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk)
                        .tint(Color.circaAccent)
                        .submitLabel(.send)
                        .focused($isFocused)
                        .onSubmit(send)

                        Button("Send", action: send)
                            .buttonStyle(.circa(.link))
                            .disabled(!model.canSend)
                            .opacity(model.canSend ? 1 : 0.45)
                    }
                    Text(statusLine)
                        .font(.circaCaption)
                        .foregroundStyle(model.status == .failed ? Color.circaDanger : Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var statusLine: String {
        switch model.status {
        case .idle: "Only Circa sees this. The foods asked for most are added first."
        case .sending: "Sending…"
        case .sent: "Sent. Thank you."
        case .failed: "Couldn't send. Check your connection and try again."
        }
    }

    private func send() {
        isFocused = false
        Task { await model.send(userId: userId) }
    }
}
