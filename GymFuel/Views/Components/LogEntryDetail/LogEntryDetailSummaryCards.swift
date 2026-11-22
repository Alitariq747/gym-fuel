import SwiftUI

/// `nil` macros draw the pending rules alone (design.md rule 1).
struct DetailMacroSummaryCard<Lead: View>: View {
    let macros: Macros?
    let certainty: CircaCertainty
    /// Takes the calorie row's place — onboarding's first guess → their total.
    private let lead: Lead?
    /// A re-estimate under way: the calorie well holds the ring, and the numbers
    /// it will replace fade.
    private var estimateStart: Date? = nil
    private var estimateFailed = false
    /// Changed numbers roll from old to new.
    private var isLive = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var calorieSize = Circa.Display.entryTotal

    init(
        macros: Macros?,
        certainty: CircaCertainty,
        estimateStart: Date? = nil,
        estimateFailed: Bool = false,
        isLive: Bool = false
    ) where Lead == EmptyView {
        self.macros = macros
        self.certainty = certainty
        lead = nil
        self.estimateStart = estimateStart
        self.estimateFailed = estimateFailed
        self.isLive = isLive
    }

    private var numberInk: Color {
        estimateStart == nil ? .circaInk : .circaInk3
    }

    init(macros: Macros?, certainty: CircaCertainty, @ViewBuilder lead: () -> Lead) {
        self.macros = macros
        self.certainty = certainty
        self.lead = lead()
    }

    private struct Part: Identifiable {
        let glyph: CircaMacroGlyph.Macro
        let name: String
        let grams: Double?
        var id: String { name }
    }

    private var parts: [Part] {
        [
            Part(glyph: .protein, name: "Protein", grams: macros?.protein),
            Part(glyph: .carbs, name: "Carbs", grams: macros?.carbs),
            Part(glyph: .fat, name: "Fat", grams: macros?.fat)
        ]
    }

    var body: some View {
        let isStacked = dynamicTypeSize.isAccessibilitySize
        let totalLayout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 12))

        CircaCard {
            VStack(alignment: .leading, spacing: 16) {
                if let lead {
                    lead
                } else {
                    totalLayout {
                        CircaMacroGlyph(.calories, size: .large)
                            .circaEstimateRing(since: estimateStart, failed: estimateFailed)
                        calorieTotal
                    }
                }

                CircaHairline(weight: .inCard)

                if isStacked {
                    stackedParts
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(parts) { part in
                                partView(part)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        stackedParts
                    }
                }
            }
        }
    }

    private var stackedParts: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(parts) { partView($0, stacked: true) }
        }
    }

    private var calorieTotal: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                calorieValue
                Text("kcal").font(.circaMono).foregroundStyle(Color.circaInk3)
            }
            .fixedSize()
            VStack(alignment: .leading, spacing: 4) {
                calorieValue
                Text("kcal").font(.circaMono).foregroundStyle(Color.circaInk3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MealCopy.calories(macros).map { "\($0) kilocalories\(certainty == .estimated ? ", estimated" : "")" } ?? "Calories, still estimating")
    }

    private var calorieValue: some View {
        CircaEstimate(MealCopy.calories(macros), certainty: certainty,
                      font: .system(size: calorieSize, weight: .semibold, design: .monospaced),
                      isLive: isLive)
            .foregroundStyle(numberInk)
    }

    private func partView(_ part: Part, stacked: Bool = false) -> some View {
        let number = part.grams.map(MealCopy.grams)
        let layout = stacked
            ? AnyLayout(HStackLayout(spacing: 12))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
        return layout {
            CircaMacroGlyph(part.glyph)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    CircaEstimate(number, certainty: certainty, font: .circaMonoLarge, isLive: isLive)
                        .foregroundStyle(numberInk)
                    Text("g").font(.circaMono).foregroundStyle(Color.circaInk3)
                }
                Text(part.name)
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(number.map { "\(part.name), \($0) grams\(certainty == .estimated ? ", estimated" : "")" } ?? "\(part.name), still estimating")
    }
}
