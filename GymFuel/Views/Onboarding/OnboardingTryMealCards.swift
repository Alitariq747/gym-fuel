import SwiftUI

/// The one raised surface on the typing screen, so it reads as the place to write.
struct TryMealField: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous)
    }

    private var count: Int { text.utf16.count }

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Your meal", text: $text, prompt: Text("Type your meal here").foregroundStyle(Color.circaInk3), axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(.title2).weight(.medium))
                    .foregroundStyle(Color.circaInk)
                    .tint(Color.circaAccent)
                    .lineLimit(3...)
                    .submitLabel(.done)
                    .focused(isFocused)
                    .accessibilityLabel("Describe a meal you often eat")

                Text("\(count) / \(OnboardingTryMealViewModel.maxTextLength)")
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel("\(count) of \(OnboardingTryMealViewModel.maxTextLength) characters")
            }
        }
        .overlay {
            if isFocused.wrappedValue {
                shape.strokeBorder(Color.circaInk, lineWidth: 1.5)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isFocused.wrappedValue)
        .circaLift()
        .contentShape(shape)
        .onTapGesture { isFocused.wrappedValue = true }
    }
}

/// Breakdown's place while the estimate is out. No spinner — design.md rule 1.
struct TryMealPendingBreakdown: View {
    @State private var start = Date.now

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                CircaSectionLabel("Breakdown")
                TimelineView(.periodic(from: start, by: 1)) { context in
                    Text(MealCopy.tryMealStatus(elapsedSeconds: Int(context.date.timeIntervalSince(start))))
                        .font(.circaMono)
                        .foregroundStyle(Color.circaAccent)
                }
                CircaProgressRail()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Circa's biggest assumption, and the one way to answer it. Without an
/// assumption it still invites the edit — the edit is the point (15c).
struct TryMealAssumptionCard: View {
    let assumption: String?
    let onChange: () -> Void

    var body: some View {
        CircaCard(.sunken, radius: Circa.Radius.cardSmall) {
            VStack(alignment: .leading, spacing: 8) {
                if let assumption {
                    CircaSectionLabel("Biggest assumption")
                    Text(assumption)
                        .font(.circaEntryTitle)
                        .foregroundStyle(Color.circaAccent)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Anything different? Change an amount and the total follows.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onChange) {
                    Label("Change an amount", systemImage: "pencil")
                }
                .buttonStyle(.circa(.secondary, height: Circa.minHitTarget))
                .padding(.top, 4)
            }
        }
    }
}

/// The calorie row once they've changed an amount: Circa's guess struck
/// through, and their total on the dotted rule.
struct TryMealChangeHeader: View {
    let correction: OnboardingTryMealViewModel.Correction

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var totalSize = Circa.Display.entryTotal

    var body: some View {
        let isStacked = dynamicTypeSize.isAccessibilitySize
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: 14))

        VStack(alignment: .leading, spacing: 14) {
            layout {
                VStack(alignment: .leading, spacing: 8) {
                    CircaSectionLabel("First guess")
                    Text(verbatim: correction.firstGuess.formatted())
                        .font(.circaMonoLarge)
                        .strikethrough()
                        .foregroundStyle(Color.circaInk3)
                }

                Image(systemName: isStacked ? "arrow.down" : "arrow.right")
                    .foregroundStyle(Color.circaInk3)
                    .padding(.bottom, isStacked ? 0 : 8)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    CircaSectionLabel("Yours", tint: .circaAccent)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        CircaEstimate(correction.total.formatted(), certainty: .estimated,
                                      font: .system(size: totalSize, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.circaAccentLarge)
                        Text("kcal").font(.circaMono).foregroundStyle(Color.circaInk3)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(MealCopy.correctionLine(firstGuess: correction.firstGuess, total: correction.total, changed: correction.changed))
                    .font(.circaMono.weight(.semibold))
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(MealCopy.correctionPromise)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Meals to start from. Lines on paper rather than buttons, so they never
/// outweigh the field they fill.
struct TryMealExamples: View {
    let examples: [String]
    let onPick: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CircaSectionLabel("Or tap one")

            VStack(spacing: 0) {
                ForEach(examples, id: \.self) { example in
                    CircaHairline()
                    Button { onPick(example) } label: {
                        HStack(spacing: 12) {
                            Text(example)
                                .font(.circaRow)
                                .foregroundStyle(Color.circaInk)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.left")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.circaAccent)
                                .accessibilityHidden(true)
                        }
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Fills in your meal")
                }
                CircaHairline()
            }
        }
    }
}
