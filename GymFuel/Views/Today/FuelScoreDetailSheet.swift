//
//  FuelScoreDetailSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/01/2026.
//

import SwiftUI


struct FuelScoreDetailSheet: View {
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: – Header
                    headerSection

                    // MARK: – Formula steps
                    formulaSection

                    // MARK: – Macro vs timing breakdown
                    breakdownSection

                    // MARK: – Up / down drivers
                    positiveDriversSection
                    negativeDriversSection

                    // MARK: – Why & how to improve
                    whyItMattersSection
                    howToImproveSection
                }
                .padding()
            }
            .navigationTitle("Fuel Score")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: – Subviews

    private var headerSection: some View {
        let tone = scoreTone(for: fuelScore.total)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today’s Fuel Score")
                        .font(.headline)

                    Text("\(fuelScore.total) / 100")
                        .font(.system(size: 34, weight: .bold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    scoreBadge(for: fuelScore.total)
                    scoreRing(score: fuelScore.total, color: tone.color)

                    Text(isTrainingDay ? "Training day" : "Rest day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if isTrainingDay {
                        Text("Intensity: \(intensityLabel)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text("LiftEats turns your daily macros and your meal timing around the session into a 0–100 score that reflects how well you fueled today.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(cardBackground(tint: tone.color))
    }

    private func scoreBadge(for score: Int) -> some View {
        let tone = scoreTone(for: score)

        return Text(tone.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tone.color.opacity(0.15))
            )
            .foregroundStyle(tone.color)
    }

    private var formulaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How we calculate it")
                .font(.headline)

            VStack(spacing: 10) {
                formulaRow(
                    step: "1",
                    title: "Daily macros",
                    body: "We compare your total calories, protein, carbs, and fats to today’s targets. This becomes your Macro Adherence (0–100)."
                )

                if isTrainingDay {
                    formulaRow(
                        step: "2",
                        title: "Pre & post-workout timing",
                        body: "We look at how much of your carbs and protein you had before and after your workout and compare it to a simple ideal pattern."
                    )

                    formulaRow(
                        step: "3",
                        title: "Training intensity",
                        body: "On harder sessions, timing matters more. On easier days, macros drive more of the score."
                    )
                } else {
                    formulaRow(
                        step: "2",
                        title: "Rest day logic",
                        body: "On rest days, timing matters less. Your Fuel Score mostly reflects how well you matched your daily macro targets."
                    )
                }
            }
        }
        .padding()
        .background(cardBackground())
    }

    private func formulaRow(step: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.headline.weight(.bold))
                .frame(width: 26, height: 26)
                .background(Circle().fill(.primary.opacity(0.1)))
                .overlay(Circle().strokeBorder(.primary.opacity(0.1)))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s breakdown")
                .font(.headline)

            HStack(spacing: 12) {
                metricCard(
                    title: "Macro adherence",
                    value: fuelScore.macroAdherence,
                    subtitle: "How closely you matched today’s macros."
                )

                metricCard(
                    title: "Timing adherence",
                    value: fuelScore.timingAdherence,
                    subtitle: isTrainingDay
                        ? "How well you placed carbs & protein around your session."
                        : "On rest days this matches macro adherence."
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Macros vs targets")
                    .font(.subheadline.weight(.semibold))

                macroRow(label: "Calories", actual: consumed.calories, target: targets.calories, unit: "kcal")
                macroRow(label: "Protein",  actual: consumed.protein,  target: targets.protein,  unit: "g")
                macroRow(label: "Carbs",    actual: consumed.carbs,    target: targets.carbs,    unit: "g")
                macroRow(label: "Fat",      actual: consumed.fat,      target: targets.fat,      unit: "g")
            }

            if isTrainingDay {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pre & post-workout focus")
                        .font(.subheadline.weight(.semibold))

                    Text("We especially look at carbs and protein you ate in the 3 hours before and 4 hours after your session.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    macroRow(label: "Pre-workout carbs", actual: preMacros.carbs, target: targets.carbs * 0.30, unit: "g")
                    macroRow(label: "Pre-workout protein", actual: preMacros.protein, target: targets.protein * 0.20, unit: "g")

                    macroRow(label: "Post-workout carbs", actual: postMacros.carbs, target: targets.carbs * 0.30, unit: "g")
                    macroRow(label: "Post-workout protein", actual: postMacros.protein, target: targets.protein * 0.30, unit: "g")
                }
            }
        }
        .padding()
        .background(cardBackground())
    }

    private func metricCard(title: String, value: Int, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
            Text("\(value)")
                .font(.title2.weight(.bold))
            Text("/ 100")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func macroRow(label: String, actual: Double, target: Double, unit: String) -> some View {
        let isOver = target > 0 && actual > target
        let accent = isOver ? Color.red : Color.accentColor
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 6)

                    Capsule()
                        .fill(accent.opacity(0.85))
                        .frame(width: geo.size.width * CGFloat(min(ratio, 1.0)),
                               height: 6)
                }
            }
            .frame(height: 8)
        }
    }

    private var positiveDriversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What pushes your Fuel Score up")
                .font(.headline)

            bullet("Hitting your daily macro targets within a reasonable range.")
            bullet("Getting enough protein across the day.")
            bullet("Placing carbs + protein around your workout (pre and post).")
            bullet("Logging your meals consistently.")
            bullet("Using the right training intensity for the day.")
        }
        .padding()
        .background(cardBackground(tint: .green))
    }

    private var negativeDriversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What pulls your Fuel Score down")
                .font(.headline)

            bullet("Being far under or over your calorie target.")
            bullet("Very low protein compared to your goal.")
            bullet("Most carbs sitting far away from your session.")
            bullet("Skipping pre- or post-workout meals entirely.")
            bullet("Marking every day as ‘all-out’ but fueling like a rest day.")
        }
        .padding()
        .background(cardBackground(tint: .red))
    }

    private var whyItMattersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why your Fuel Score matters")
                .font(.headline)
            bullet("More energy and better performance set-to-set.")
            bullet("Stronger recovery between sessions.")
            bullet("Better support for muscle growth and strength over time.")
            bullet("Less guesswork, more consistent progress.")
        }
    }

    private var howToImproveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to keep improving")
                .font(.headline)

            Text("Macros")
                .font(.subheadline.weight(.semibold))
            bullet("Aim roughly for your daily targets instead of perfection.")
            bullet("Prioritize hitting your protein goal.")
            bullet("Adjust portion sizes rather than skipping meals.")

            Text("Timing")
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            bullet("Plan 1–2 carb + protein meals in the 3 hours before training.")
            bullet("Get carbs + protein in the 4 hours after training.")
            bullet("Avoid pushing your biggest meal far away from your session.")

            Text("Score ranges")
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            bullet("85+ → Dialed in fueling.")
            bullet("70–84 → Solid, just refine details.")
            bullet("50–69 → Inconsistent; fix macros or timing.")
            bullet("Below 50 → Big opportunity for quick wins.")
        }
        .padding(.bottom, 8)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(text)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func scoreTone(for score: Int) -> (label: String, color: Color) {
        switch score {
        case 85...:
            return ("Dialed in", .green)
        case 70..<85:
            return ("Solid", .blue)
        case 50..<70:
            return ("Needs refinement", .orange)
        default:
            return ("Big opportunity", .red)
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
        .frame(width: 64, height: 64)
    }

    @ViewBuilder
    private func cardBackground(tint: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16)

        shape
            .fill(.ultraThinMaterial)
            .overlay(
                shape.stroke(.primary.opacity(0.06), lineWidth: 1)
            )
            .overlay {
                if let tint {
                    LinearGradient(
                        colors: [tint.opacity(0.16), tint.opacity(0.0)],
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
        AppBackground()
        FuelScoreDetailSheet(dayLog: DayLog.demoTrainingDay, fuelScore: FuelScore(total: 89, macroAdherence: 78, timingAdherence: 98), targets: Macros(calories: 3000, protein: 175, carbs: 250, fat: 50), consumed: Macros(calories: 3100, protein: 120, carbs: 180, fat: 32), preMacros: Macros(calories: 1500, protein: 55, carbs: 82, fat: 15), postMacros: Macros(calories: 1000, protein: 55, carbs: 70, fat: 35))
    }
}
