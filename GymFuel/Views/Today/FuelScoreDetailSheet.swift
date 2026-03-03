//
//  FuelScoreDetailSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/01/2026.
//

import SwiftUI

struct FuelScoreDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let dayLog: DayLog
    let fuelScore: FuelScore
    let targets: Macros
    let consumed: Macros
    let preMacros: Macros
    let postMacros: Macros

    private var isTrainingDay: Bool { dayLog.isTrainingDay }
    private var intensityLabel: String {
        switch dayLog.trainingIntensity {
        case .normal:   return "Normal"
        case .hard:     return "Hard"
        case .allOut:   return "All-out"
        case .recovery: return "Recovery"
        case .none:     return "—"
        }
    }

    private var scoreTone: (label: String, color: Color) {
        switch fuelScore.total {
        case 85...:
            return ("Crushing it", .green)
        case 70..<85:
            return ("On track", Color("fuelBlue"))
        case 50..<70:
            return ("Getting there", .orange)
        default:
            return ("Off track", .red)
        }
    }

    private var heroSummary: String {
        if isTrainingDay {
            switch fuelScore.total {
            case 85...: return "Fueling supported your training really well today."
            case 70..<85: return "Solid session fuel. A small tweak can lift your score."
            case 50..<70: return "Macros or timing were a bit off today."
            default: return "Fueling didn’t support the session. Reset with the next meal."
            }
        } else {
            switch fuelScore.total {
            case 85...: return "Great recovery nutrition and balance today."
            case 70..<85: return "Rest-day balance is solid."
            case 50..<70: return "Rest-day macros could be tighter."
            default: return "Rest-day intake is off target today."
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroSection
                    breakdownSection
                    macroTargetsSection
                    if isTrainingDay {
                        timingFocusSection
                    }
                    tipsSection
                    calculationSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Fuel Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .padding(8)
                            .background(
                                Circle().fill(Color(.systemGray6))
                            )
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today’s Fuel Score")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(scoreTone.label)
                        .font(.title3.weight(.semibold))

                    Text(heroSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    scoreRing(score: fuelScore.total, color: scoreTone.color)

                    Text(isTrainingDay ? "Training day" : "Rest day")
                        .font(.caption2.weight(.semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule().fill(Color(.systemGray6))
                        )

                    if isTrainingDay {
                        Text("Intensity: \(intensityLabel)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground(tint: scoreTone.color))
    }


    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today’s breakdown")
                .font(.headline)

            HStack(spacing: 12) {
                metricCard(
                    title: "Macros",
                    value: fuelScore.macroAdherence,
                    subtitle: "Daily targets",
                    tint: Color("fuelBlue")
                )

                metricCard(
                    title: isTrainingDay ? "Timing" : "Recovery",
                    value: fuelScore.timingAdherence,
                    subtitle: isTrainingDay ? "Around workout" : "Rest-day focus",
                    tint: Color("fuelGreen")
                )
            }
        }
        .padding(14)
        .background(cardBackground())
    }

    private var macroTargetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Macros vs targets")
                .font(.headline)

            macroRow(label: "Calories", actual: consumed.calories, target: targets.calories, unit: "kcal")
            macroRow(label: "Protein", actual: consumed.protein, target: targets.protein, unit: "g")
            macroRow(label: "Carbs", actual: consumed.carbs, target: targets.carbs, unit: "g")
            macroRow(label: "Fat", actual: consumed.fat, target: targets.fat, unit: "g")
        }
        .padding(14)
        .background(cardBackground())
    }

    private var timingFocusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pre & post‑workout focus")
                .font(.headline)

            Text("We emphasize carbs and protein within a few hours before and after your session.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            if let timingTip = timingAdjustmentTip {
                tipRow(text: timingTip)
            }

            macroRow(label: "Pre‑workout carbs", actual: preMacros.carbs, target: targets.carbs * 0.30, unit: "g")
            macroRow(label: "Pre‑workout protein", actual: preMacros.protein, target: targets.protein * 0.20, unit: "g")
            macroRow(label: "Post‑workout carbs", actual: postMacros.carbs, target: targets.carbs * 0.30, unit: "g")
            macroRow(label: "Post‑workout protein", actual: postMacros.protein, target: targets.protein * 0.30, unit: "g")
        }
        .padding(14)
        .background(cardBackground())
    }

    private var timingAdjustmentTip: String? {
        guard let start = dayLog.sessionStart else { return nil }
        let hour = Calendar.current.component(.hour, from: start)
        switch hour {
        case 0..<11:
            return "Morning training: LiftEats weighs post‑workout fuel a bit more."
        case 11..<17:
            return "Midday training: LiftEats keeps pre and post fuel balanced."
        default:
            return "Evening training: LiftEats weighs pre‑workout fuel a bit more."
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick tips")
                .font(.headline)

            ForEach(tips, id: \.self) { tip in
                tipRow(text: tip)
            }
        }
        .padding(14)
        .background(cardBackground())
    }

    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How it’s calculated")
                .font(.headline)

            tipRow(text: "Macro adherence compares your daily totals to targets.")
            if isTrainingDay {
                tipRow(text: "Timing adherence checks carbs and protein around the workout.")
            } else {
                tipRow(text: "On rest days, timing has less weight and macros lead.")
            }
        }
        .padding(14)
        .background(cardBackground())
    }

    private var tips: [String] {
        if isTrainingDay {
            switch fuelScore.total {
            case 85...:
                return [
                    "Keep the same pre‑workout pattern next session.",
                    "Match protein to your target to stay consistent."
                ]
            case 70..<85:
                return [
                    "Shift 20–30g carbs closer to training.",
                    "Add a protein‑focused snack today."
                ]
            case 50..<70:
                return [
                    "Log the next meal and push protein up.",
                    "Aim for carbs before or after training."
                ]
            default:
                return [
                    "Start with one balanced meal now.",
                    "Plan a simple pre‑workout meal next session."
                ]
            }
        } else {
            switch fuelScore.total {
            case 85...:
                return [
                    "Great recovery balance—keep it steady.",
                    "Stay near your protein target."
                ]
            case 70..<85:
                return [
                    "Keep calories close to target.",
                    "Protein can still go a bit higher."
                ]
            case 50..<70:
                return [
                    "Tighten protein and total calories.",
                    "Avoid skipping meals on rest days."
                ]
            default:
                return [
                    "Reset with a balanced meal now.",
                    "Focus on protein and total calories first."
                ]
            }
        }
    }

    private func metricCard(title: String, value: Int, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("\(value)")
                .font(.title3.weight(.bold))
            Text("/ 100 • \(subtitle)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }


    private func macroRow(label: String, actual: Double, target: Double, unit: String) -> some View {
        let isOver = target > 0 && actual > target
        let accent = isOver ? Color.fuelRed : Color("FuelBlue")
        let ratio: Double
        if target > 0, target.isFinite, actual.isFinite {
            let raw = actual / target
            ratio = raw.isFinite ? min(raw, 2.0) : 0
        } else {
            ratio = 0
        }

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(actual.rounded())) / \(Int(target.rounded())) \(unit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5).opacity(0.4))
                        .frame(height: 6)

                    Capsule()
                        .fill(accent.opacity(0.9))
                        .frame(width: geo.size.width * CGFloat(min(ratio, 1.0)), height: 6)
                }
            }
            .frame(height: 8)
        }
    }

    private func tipRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color("FuelGreen"))
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func scoreRing(score: Int, color: Color) -> some View {
        let progress = max(0, min(Double(score) / 100.0, 1.0))

        return ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.subheadline.weight(.bold))
                Text("score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72, height: 72)
    }

    @ViewBuilder
    private func cardBackground(tint: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16)

        shape
            .fill(Color(.secondarySystemBackground))
            .overlay(
                shape.stroke(Color(.systemGray5), lineWidth: 1)
            )
            .overlay {
                if let tint {
                    LinearGradient(
                        colors: [tint.opacity(0.12), tint.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(shape)
                }
            }
    }
}

#Preview {
    ZStack {
 
        FuelScoreDetailSheet(
            dayLog: DayLog.demoTrainingDay,
            fuelScore: FuelScore(total: 89, macroAdherence: 78, timingAdherence: 98),
            targets: Macros(calories: 3000, protein: 175, carbs: 250, fat: 50),
            consumed: Macros(calories: 3100, protein: 120, carbs: 180, fat: 32),
            preMacros: Macros(calories: 1500, protein: 55, carbs: 82, fat: 15),
            postMacros: Macros(calories: 1000, protein: 55, carbs: 70, fat: 35)
        )
    }
}
