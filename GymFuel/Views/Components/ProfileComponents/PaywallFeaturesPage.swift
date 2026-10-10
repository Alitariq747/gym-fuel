import SwiftUI

struct PaywallFeaturesPage: View {
    let context: PaywallContext?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var planSize = Circa.Display.planTotal

    init(context: PaywallContext? = nil) {
        self.context = context
    }

    private var rowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 13))
    }

    private let features: [(symbol: String, title: String)] = [
        ("text.viewfinder", "Describe or photograph a meal"),
        ("list.bullet.rectangle", "See what was assumed"),
        ("slider.horizontal.3", "Correct your version"),
        ("bookmark", "Save it for next time"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let context {
                PaywallPageHeader(label: "Your plan is ready", subtitle: context.subtitle) {
                    plan(context)
                }
                if let meal = context.meal {
                    mealPanel(meal)
                }
            } else {
                PaywallPageHeader(
                    label: "Circa Pro",
                    title: "Understand the food you actually eat.",
                    subtitle: "See what went into an estimate, correct what differs, and save your version."
                )
            }

            VStack(spacing: 0) {
                ForEach(features, id: \.title) { feature in
                    if feature.title != features.first?.title {
                        CircaHairline(weight: .inCard)
                    }
                    rowLayout {
                        CircaSymbolWell(symbol: feature.symbol)
                        Text(feature.title)
                            .font(.circaRow)
                            .foregroundStyle(Color.circaInk)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(ProfileCardBackground())
        }
    }

    /// A saved target, not an estimate, so no dotted rule (`design.md` rule 1).
    private func plan(_ context: PaywallContext) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(context.calories.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(size: planSize, weight: .semibold, design: .monospaced))
                Text("kcal a day")
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
            }
            if let planLine = context.planLine {
                Text(planLine)
                    .font(.circaRow.weight(.medium))
            }
        }
    }

    private func mealPanel(_ meal: PaywallContext.Meal) -> some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        return CircaCard(.sunken, radius: Circa.Radius.cardSmall) {
            VStack(alignment: .leading, spacing: 7) {
                CircaSectionLabel("The meal you tried")
                layout {
                    Text(meal.title)
                        .font(.circaRow.weight(.semibold))
                        .foregroundStyle(Color.circaInk)
                    if !isLarge { Spacer(minLength: 0) }
                    CircaEstimate("\(meal.kcal.formatted(.number.precision(.fractionLength(0)))) kcal", certainty: .estimated)
                }
                Text(meal.line)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
