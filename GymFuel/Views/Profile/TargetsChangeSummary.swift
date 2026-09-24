//
//  TargetsChangeSummary.swift
//  GymFuel
//

import SwiftUI

/// What the editor is about to save, after the user has picked how to reconcile a
/// number they typed. A part of `TargetsEditorSheet` rather than a reusable
/// component — it is the only screen that has a before and an after to show.
///
/// "Ready to save" rather than "Updated": nothing has been written yet, and the
/// Save button is still the thing that writes it.
struct TargetsChangeSummary: View {
    let changes: [TargetChange]
    /// Present only when a floor lifted the calories above what was asked for.
    let floorNote: String?
    let onDismiss: () -> Void

    var body: some View {
        CircaCard(.sunken, radius: Circa.Radius.cardSmall) {
            VStack(alignment: .leading, spacing: 8) {
                // Accent and a checkmark: this app has no green, and `design.md`
                // rule 5 keeps colour meaning one thing.
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaAccent)
                        .accessibilityHidden(true)
                    CircaSectionLabel("Ready to save")
                }

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(changes) { change in
                        Text(TargetsCopy.changeLine(change))
                            .font(.circaMono)
                            .monospacedDigit()
                            .foregroundStyle(Color.circaInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel(TargetsCopy.changeLineSpoken(change))
                    }
                }

                if let floorNote {
                    Text(floorNote)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(TargetsCopy.reviewChanges)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.circa(.quiet))
                    // Cancels the horizontal padding `CircaButtonStyle` puts on
                    // text tiers, so the label lines up with the lines above it.
                    .padding(.leading, -10)
            }
        }
    }
}

#if DEBUG
#Preview("Ready to save") {
    VStack {
        TargetsChangeSummary(
            changes: [
                TargetChange(field: .protein, before: 170, after: 157),
                TargetChange(field: .fat, before: 60, after: 55),
            ],
            floorNote: nil,
            onDismiss: {}
        )
        TargetsChangeSummary(
            changes: [TargetChange(field: .calories, before: 900, after: 1_500)],
            floorNote: "Saving as 1,500 kcal — the lowest this app will set.",
            onDismiss: {}
        )
    }
    .padding(Circa.Space.screenMargin)
    .circaPaper()
}
#endif
