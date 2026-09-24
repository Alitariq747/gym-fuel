import SwiftUI

/// The day's headline: calories left, what that is out of, and the three macro
/// bars. Built from the `Day` artboard.
///
/// One number is obviously the most important on the screen — `design.md`, "the
/// tension to watch". The ring, the Eaten/Target pair and the three glyph tiles
/// it replaced were three competing focal points.
struct DailyMacroDetailSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let targetMacros: Macros
    let consumedMacros: Macros
    /// Entries still being read. Built from the `Analysing · text + photo`
    /// artboard: while any are, this line names them instead of the of-target
    /// figure, because the figure beside it counts only what has settled.
    var analysingCount: Int = 0

    private var remainingCalories: Int {
        Int((targetMacros.calories - consumedMacros.calories).rounded())
    }

    private var remainingLabel: String {
        remainingCalories < 0 ? "over" : "left"
    }

    private var consumed: Int { Int(consumedMacros.calories.rounded()) }
    private var target: Int { Int(targetMacros.calories.rounded()) }

    private var countAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.55)
    }

    var body: some View {
        CircaCard(
            .raised,
            inset: EdgeInsets(top: 15, leading: Circa.Space.cardInset,
                              bottom: 15, trailing: Circa.Space.cardInset)
        ) {
            VStack(alignment: .leading, spacing: 13) {
                headline
                CircaMacroBars(
                    protein: macro(consumedMacros.protein, targetMacros.protein),
                    carbs: macro(consumedMacros.carbs, targetMacros.carbs),
                    fat: macro(consumedMacros.fat, targetMacros.fat)
                )
            }
        }
    }

    private var headline: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(abs(remainingCalories).formatted())
                    .font(.circaMonoLarge)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(countAnimation, value: remainingCalories)
                Text(remainingLabel)
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk2)
                    .animation(.easeOut(duration: 0.2), value: remainingLabel)
            }

            Spacer(minLength: 8)

            Text(trailingLine)
                .font(.circaMono)
                .monospacedDigit()
                .foregroundStyle(analysingCount > 0 ? Color.circaAccent : Color.circaInk3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(abs(remainingCalories)) calories \(remainingLabel), \(trailingLine)"
        )
    }

    private var trailingLine: String {
        if analysingCount > 0 {
            return "\(analysingCount) still estimating"
        }

        // The `Empty day` artboard. An untouched day reads as the whole day
        // still ahead, not as a zero.
        if consumed == 0 {
            return "the whole day"
        }

        return "\(consumed.formatted()) of \(target.formatted())"
    }

    private func macro(_ current: Double, _ target: Double) -> CircaMacroValue {
        CircaMacroValue(consumed: Int(current.rounded()), target: Int(target.rounded()))
    }
}

#Preview {
    DailyMacroDetailSheet(
        targetMacros: Macros(calories: 2400, protein: 165, carbs: 240, fat: 80),
        consumedMacros: Macros(calories: 1380, protein: 81, carbs: 134, fat: 56)
    )
    .padding()
    .circaPaper()
}

#Preview("Still estimating") {
    DailyMacroDetailSheet(
        targetMacros: Macros(calories: 2400, protein: 165, carbs: 240, fat: 80),
        consumedMacros: Macros(calories: 420, protein: 9, carbs: 48, fat: 21),
        analysingCount: 2
    )
    .padding()
    .circaPaper()
}
