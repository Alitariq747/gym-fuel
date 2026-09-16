//
//  CheckInCard.swift
//  GymFuel
//

import SwiftUI

/// The prompt that a weekly check-in is waiting.
///
/// Recessed, like the check-in prompt on the kit gallery. It says nothing about
/// what the check-in found: no target has moved until the user chooses to move
/// it, so the card never says one did.
struct CheckInCard: View {
    let onOpen: () -> Void

    var body: some View {
        CircaCard(.sunken, radius: Circa.Radius.cardSmall) {
            VStack(alignment: .leading, spacing: 6) {
                CircaSectionLabel("Your week is ready")
                Text("See how your pace is going.")
                    .font(.circaRow)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open check-in", action: onOpen)
                    .buttonStyle(.circa(.link))
                    .padding(.leading, -10)
            }
        }
    }
}

#Preview {
    CheckInCard(onOpen: {})
        .padding()
        .circaPaper()
}
