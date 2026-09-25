import SwiftUI

/// What the estimate was read as.
///
/// The prose only. What Circa assumed sits on the breakdown rows instead, beside
/// the amount it is an assumption about — an assumption listed away from its
/// ingredient names something the reader cannot then go and correct.
///
/// No confidence figure, by rule: `design.md` rule 1 asks for specific
/// uncertainty copy — "2 tbsp of oil in the stew" — in place of a percentage
/// nothing has calibrated and a reader would take for an accuracy rate.
struct MealAnalysisCard: View {
    let explanation: String

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 6) {
                CircaSectionLabel("How this was estimated")

                Text(explanation)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The way into `NutritionSourcesView`. A row on the paper rather than a button
/// inside the card above, so a meal whose explanation a manual total superseded
/// still has one.
///
/// It owns its top rule: the `Entry` artboard draws the line as the row's border,
/// with the 44 pt target directly beneath it.
struct MealSourcesRow: View {
    @State private var showNutritionSources = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CircaHairline()
            sourcesButton
        }
    }

    private var sourcesButton: some View {
        Button {
            showNutritionSources = true
        } label: {
            HStack(spacing: 10) {
                Text("AI estimate · how this works & sources")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                Image(systemName: "chevron.forward")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk3)
            }
            .frame(minHeight: Circa.minHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showNutritionSources) {
            NutritionSourcesView()
        }
    }
}
