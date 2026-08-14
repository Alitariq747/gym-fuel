//
//  NutritionSourcesView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/08/2026.
//

import SwiftUI

/// Discloses the science behind every target, score, and estimate LiftEats shows.
/// Presented as a sheet from Settings, the onboarding summary, the Goal Fit
/// explainer, and the LiftEats Analysis card.
struct NutritionSourcesView: View {
    var primaryButtonTitle: String = "Done"
    var onPrimaryAction: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let methods: [NutritionMethod] = [
        NutritionMethod(
            id: "calories",
            index: "01",
            emoji: "🔥",
            title: "Your daily calorie target",
            tint: .fuelOrange,
            body: "We start with your resting energy — the calories your body uses at rest — using the Mifflin–St Jeor equation, the most widely validated predictive equation for healthy adults.",
            formula: """
            Resting energy (kcal/day)
            (10 × weight kg) + (6.25 × height cm) − (5 × age)
                +  5    if male
                − 161   if female
                −  78   if prefer not to say

            Daily target
            resting energy × activity factor + goal offset
            """,
            footnote: "Activity factors are 1.35 (mostly sitting), 1.50 (moderately active), and 1.70 (physically demanding). Goal offsets are +250 kcal for Lean Bulk, 0 for Maintain, and −300 kcal for Cut — deliberately moderate rates of change.",
            sourceIDs: ["mifflin", "iom"]
        ),
        NutritionMethod(
            id: "macros",
            index: "02",
            emoji: "💪",
            title: "Your protein, carb, and fat split",
            tint: .fuelBlue,
            body: "Protein is set at 1.8 g per kg of body weight, raised to 2.2 g/kg on a Cut, where higher intakes help protect lean mass in a calorie deficit. Fat is set at 0.8 g/kg, raised to 0.9 g/kg on Lean Bulk. Carbohydrate fills whatever calories remain.",
            formula: """
            protein g = weight kg × 1.8   (2.2 on Cut)
            fat g     = weight kg × 0.8   (0.9 on Lean Bulk)
            carbs g   = (target kcal − protein kcal − fat kcal) ÷ 4
            """,
            footnote: "Calories per gram use the Atwater factors: 4 kcal for protein, 4 for carbohydrate, 9 for fat.",
            sourceIDs: ["issn", "morton", "iom", "fao"]
        ),
        NutritionMethod(
            id: "goalfit",
            index: "03",
            emoji: "🎯",
            title: "The Goal Fit score",
            tint: .fuelGreen,
            body: "Each meal is scored 0–100 across five weighted factors: useful protein, protein efficiency, goal calories, macro balance, and practicality. The reference points are drawn from published research — roughly 35 g of protein as a meaningful per-meal dose, around 6 g of protein per 100 kcal as strong protein efficiency, and fat share limits that reflect the accepted 20–35% of energy from fat.",
            formula: nil,
            footnote: "Weights shift with your goal, and hard ceilings apply for extreme calories, very low protein efficiency, or very high fat. The score compares a meal to your goal — it is not a judgement of the food itself.",
            sourceIDs: ["schoenfeld", "issn", "iom"]
        ),
        NutritionMethod(
            id: "exercise",
            index: "04",
            emoji: "🏃",
            title: "Exercise calories",
            tint: .purple,
            body: "Calories burned are estimated from the activity type, duration, and intensity you log, combined with typical adult body-size assumptions. These follow the metabolic equivalent (MET) values published in the Compendium of Physical Activities.",
            formula: nil,
            footnote: "Burn estimates vary considerably between individuals. Treat them as a rough guide, not a measurement.",
            sourceIDs: ["ainsworth"]
        ),
        NutritionMethod(
            id: "ai",
            index: "05",
            emoji: "🤖",
            title: "Food estimates and LiftEats Analysis",
            tint: .cyan,
            body: "Calories and macros for a logged meal are estimated by an AI model from your description or photo. They are approximations, not laboratory measurements, and every entry shows a confidence level so you can see how certain the estimate is.",
            formula: nil,
            footnote: "The analysis discusses protein, fat, carbohydrate, fibre, sugar, sodium, and cooking method qualitatively only. It never fabricates exact values for nutrients it cannot estimate, and it does not give medical advice. Reference nutrient data comes from USDA FoodData Central; general dietary framing follows the Dietary Guidelines for Americans.",
            sourceIDs: ["usda", "dga"]
        )
    ]

    private let sources: [NutritionSource] = [
        NutritionSource(
            id: "mifflin",
            shortLabel: "Mifflin MD, et al. Am J Clin Nutr. 1990;51(2):241–247",
            citation: "Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. A new predictive equation for resting energy expenditure in healthy individuals. Am J Clin Nutr. 1990;51(2):241–247.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/2305711/")
        ),
        NutritionSource(
            id: "iom",
            shortLabel: "Institute of Medicine. Dietary Reference Intakes for Energy and Macronutrients, 2005",
            citation: "Institute of Medicine. Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids. Washington, DC: National Academies Press; 2005.",
            url: URL(string: "https://nap.nationalacademies.org/catalog/10490")
        ),
        NutritionSource(
            id: "issn",
            shortLabel: "ISSN Position Stand: Protein and Exercise. J Int Soc Sports Nutr. 2017;14:20",
            citation: "Jäger R, Kerksick CM, Campbell BI, et al. International Society of Sports Nutrition Position Stand: protein and exercise. J Int Soc Sports Nutr. 2017;14:20.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/28642676/")
        ),
        NutritionSource(
            id: "morton",
            shortLabel: "Morton RW, et al. Br J Sports Med. 2018;52(6):376–384",
            citation: "Morton RW, Murphy KT, McKellar SR, et al. A systematic review, meta-analysis and meta-regression of the effect of protein supplementation on resistance training-induced gains in muscle mass and strength in healthy adults. Br J Sports Med. 2018;52(6):376–384.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/28698222/")
        ),
        NutritionSource(
            id: "schoenfeld",
            shortLabel: "Schoenfeld BJ, Aragon AA. J Int Soc Sports Nutr. 2018;15:10",
            citation: "Schoenfeld BJ, Aragon AA. How much protein can the body use in a single meal for muscle-building? Implications for daily protein distribution. J Int Soc Sports Nutr. 2018;15:10.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/29497353/")
        ),
        NutritionSource(
            id: "ainsworth",
            shortLabel: "Ainsworth BE, et al. 2011 Compendium of Physical Activities. Med Sci Sports Exerc. 2011;43(8):1575–1581",
            citation: "Ainsworth BE, Haskell WL, Herrmann SD, et al. 2011 Compendium of Physical Activities: a second update of codes and MET values. Med Sci Sports Exerc. 2011;43(8):1575–1581.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/21681120/")
        ),
        NutritionSource(
            id: "fao",
            shortLabel: "FAO. Food Energy — Methods of Analysis and Conversion Factors, 2003",
            citation: "Food and Agriculture Organization of the United Nations. Food Energy — Methods of Analysis and Conversion Factors. FAO Food and Nutrition Paper 77. Rome; 2003.",
            url: URL(string: "https://www.fao.org/4/y5022e/y5022e00.htm")
        ),
        NutritionSource(
            id: "usda",
            shortLabel: "USDA FoodData Central",
            citation: "U.S. Department of Agriculture, Agricultural Research Service. FoodData Central.",
            url: URL(string: "https://fdc.nal.usda.gov")
        ),
        NutritionSource(
            id: "dga",
            shortLabel: "Dietary Guidelines for Americans, 2020–2025",
            citation: "U.S. Departments of Agriculture and Health and Human Services. Dietary Guidelines for Americans, 2020–2025. 9th ed.",
            url: URL(string: "https://www.dietaryguidelines.gov")
        )
    ]

    private var background: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground).opacity(0.82) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.quaternaryLabel)
    }

    private func source(_ id: String) -> NutritionSource? {
        sources.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    disclaimerCard

                    VStack(spacing: 12) {
                        ForEach(methods) { method in
                            NutritionMethodCard(
                                method: method,
                                sources: method.sourceIDs.compactMap(source),
                                cardBackground: cardBackground,
                                cardStroke: cardStroke
                            )
                        }
                    }

                    preferNotToSayCard
                    referenceList
                    closingNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 22)
            }

            primaryButton
        }
        .background(background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 36)

            VStack(spacing: 6) {
                Text("Where our numbers come from")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Every target, score, and estimate in LiftEats traces back to published nutrition and exercise science. Here is exactly what we use, and where it came from.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: "cross.case.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.fuelRed)
                    .frame(width: 34, height: 34)
                    .background(Color.fuelRed.opacity(colorScheme == .dark ? 0.2 : 0.12), in: Circle())

                Text("This is not medical advice")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
            }

            Text("LiftEats is a nutrition tracking tool for generally healthy adults. It is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease or condition.\n\nTalk to a doctor or a registered dietitian before making significant changes to how you eat or train — particularly if you are pregnant or nursing, under 18, managing a medical condition, taking medication, or have any history of disordered eating.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.fuelRed.opacity(colorScheme == .dark ? 0.4 : 0.2), lineWidth: 1)
        )
        .shadow(color: Color.fuelRed.opacity(colorScheme == .dark ? 0.14 : 0.07), radius: 18, y: 9)
    }

    private var preferNotToSayCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("⚖️")
                .font(.system(size: 18))
                .frame(width: 34, height: 34)
                .background(Color(.tertiarySystemFill), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("A note on “Prefer not to say”")
                    .font(.subheadline.weight(.semibold))

                Text("The Mifflin–St Jeor equation publishes two constants: +5 for men and −161 for women. There is no published constant for an unspecified sex. When you choose “Prefer not to say,” LiftEats uses −78, the exact midpoint between the two.\n\nThat midpoint is our own choice, not a research finding. It keeps your target reasonable without asking for information you would rather not give, but it is less precise than selecting male or female. You can change this at any time in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
    }

    private var referenceList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Full reference list")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 0) {
                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 34)
                    }

                    NutritionSourceRow(number: index + 1, source: source)
                }
            }
            .padding(14)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
        }
    }

    private var closingNote: some View {
        VStack(spacing: 6) {
            Text("Targets are starting points, not prescriptions. Bodies differ, and the equations above describe averages. Adjust based on how you actually respond over time.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Last reviewed August 2026")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private var primaryButton: some View {
        Button {
            if let onPrimaryAction {
                onPrimaryAction()
            } else {
                dismiss()
            }
        } label: {
            Text(primaryButtonTitle)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}

// MARK: - Entry point

/// Shared capsule affordance that opens `NutritionSourcesView`.
/// Owns its own presentation state so callers stay a single line.
struct NutritionSourcesLinkButton: View {
    var title: String
    var systemImage: String = "books.vertical.fill"

    @State private var isPresented = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))

                Text(title)
                    .font(.footnote.weight(.semibold))

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.7)
            }
            .foregroundStyle(Color.fuelBlue)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(Color.fuelBlue.opacity(colorScheme == .dark ? 0.16 : 0.10))
            )
            .overlay(
                Capsule().stroke(Color.fuelBlue.opacity(colorScheme == .dark ? 0.32 : 0.20), lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            NutritionSourcesView()
        }
    }
}

// MARK: - Models

private struct NutritionMethod: Identifiable {
    let id: String
    let index: String
    let emoji: String
    let title: String
    let tint: Color
    let body: String
    let formula: String?
    let footnote: String?
    let sourceIDs: [String]
}

private struct NutritionSource: Identifiable {
    let id: String
    /// Compact label used inline on a method card.
    let shortLabel: String
    /// Full reference, shown in the reference list at the bottom.
    let citation: String
    let url: URL?
}

// MARK: - Rows

private struct NutritionMethodCard: View {
    let method: NutritionMethod
    let sources: [NutritionSource]
    let cardBackground: Color
    let cardStroke: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(method.emoji)
                    .font(.system(size: 21))
                    .frame(width: 48, height: 48)
                    .background(method.tint.opacity(colorScheme == .dark ? 0.18 : 0.12), in: Circle())
                    .overlay(Circle().stroke(method.tint.opacity(0.24), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.index)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(method.tint)

                    Text(method.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            Text(method.body)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if let formula = method.formula {
                Text(formula)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineSpacing(3)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(method.tint.opacity(colorScheme == .dark ? 0.10 : 0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(method.tint.opacity(0.18), lineWidth: 1)
                    )
            }

            if let footnote = method.footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !sources.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 7) {
                    Text("Based on")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    ForEach(sources) { source in
                        NutritionSourceChip(source: source, tint: method.tint)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
    }
}

private struct NutritionSourceChip: View {
    let source: NutritionSource
    let tint: Color

    var body: some View {
        let content = HStack(alignment: .top, spacing: 6) {
            Image(systemName: "link")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(tint)
                .padding(.top, 2)

            Text(source.shortLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())

        return Group {
            if let url = source.url {
                Link(destination: url) { content }
            } else {
                content
            }
        }
        .buttonStyle(.plain)
    }
}

private struct NutritionSourceRow: View {
    let number: Int
    let source: NutritionSource

    var body: some View {
        let content = HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(Color(.tertiarySystemFill), in: Circle())

            Text(source.citation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            if source.url != nil {
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 3)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 11)

        return Group {
            if let url = source.url {
                Link(destination: url) { content }
            } else {
                content
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NutritionSourcesView()
}
