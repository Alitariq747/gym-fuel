//
//  SessionCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/12/2025.
//

import SwiftUI

struct SessionCard: View {
    @Binding var draft: TodayView.DaySessionDraft
    let onSave: () -> Void

    @State private var isExpanded = false
    @State private var caption: String = "Let’s lift."
    @State private var showTimePickerField = false


    private let captions = [
        "Work mode.",
        "Let’s lift.",
        "No excuses. Just reps.",
        "Make it count.",
        "Show up. Do work.",
        "It's lift time."
    ]

    private func hapticSoft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // COLLAPSED HEADER (always visible)
            Button {
                hapticSoft()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 16) {
                    // Icon
                    leadingIcon

                    // Title + caption
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headerTitle)
                            .font(.subheadline)
                        Text(headerSubtitle)
                            .font(.title3.bold())
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // EXPANDED EDITING CONTENT
            if isExpanded {
                Divider()
                    .padding(.vertical, 4)

                // Training day toggle
                Toggle("Training day", isOn: $draft.isTrainingDay)
                    .onChange(of: draft.isTrainingDay) { _, isOn in
                        hapticSoft()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            if !isOn {
                                draft.intensity = nil
                                draft.sessionType = nil
                            } else if draft.intensity == nil {
                                draft.intensity = .normal
                            }
                        }
                    }

                if draft.isTrainingDay {
                    VStack(spacing: 10) {

                        // INTENSITY as a Menu with our custom card label
                        Menu {
                            Button("Not set") { draft.intensity = nil }
                            ForEach(TrainingIntensity.allCases, id: \.self) { intensity in
                                Button(intensity.rawValue.capitalized) {
                                    draft.intensity = intensity
                                }
                            }
                        } label: {
                            fieldRow(
                                systemImage: "flame.fill",
                                title: "Intensity",
                                value: intensityLabel
                            )
                        }
                        .buttonStyle(.plain)
                        Menu {
                            Button("Not set") { draft.sessionType = nil }
                            ForEach(SessionType.allCases, id: \.self) { t in
                                Button(t.rawValue.capitalized) {
                                    draft.sessionType = t
                                }
                            }
                        } label: {
                            fieldRow(
                                systemImage: "dumbbell.fill",
                                title: "Session type",
                                value: typeLabel
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                showTimePickerField.toggle()
                            }
                        } label: {
                            fieldRow(
                                systemImage: "clock.fill",
                                title: "Workout time",
                                value: timeLabel
                            )
                        }
                        .buttonStyle(.plain)

                        if showTimePickerField {
                            DatePicker(
                                "",
                                selection: $draft.sessionStart,
                                displayedComponents: [.hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))

                }


                // Save button
                HStack {
                    Spacer()
                    Button {
                        hapticSuccess()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            onSave()
                            isExpanded = false
                        }
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.liftEatsCoral)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                           
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
//        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0, y: 4
        )
        .onAppear {
            caption = captions.randomElement() ?? caption
        }
    }

    // MARK: - Collapsed header helpers

    private var leadingIcon: some View {
        Group {
            if draft.isTrainingDay {
                Text("🏋️")
                    .font(.system(size: 22, weight: .semibold))
                    .padding(8)
                    .background(Color.white, in: Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
            } else {
                Text("😴")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(8)
                    .background(Color.white, in: Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
            }
        }
    }

    private var headerTitle: String {
        if draft.isTrainingDay {
            // training titles (similar to your TrainingCard)
            return draft.sessionType?.displayName ?? "Set type 👉🏻"
        } else {
            return "Prioritize recovery & sleep."
        }
    }

    private var headerSubtitle: String {
        if draft.isTrainingDay {
            return caption
        } else {
            return "Rest Day"
        }
    }
    
    private func fieldRow(systemImage: String,
                          title: String,
                          value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
            }

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private var intensityLabel: String {
        if let i = draft.intensity {
            return i.rawValue.capitalized
        } else {
            return "Choose intensity"
        }
    }

    private var typeLabel: String {
        if let t = draft.sessionType {
            return t.rawValue.capitalized
        } else {
            return "Choose session type"
        }
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: draft.sessionStart)
    }

}


#Preview {
    ZStack {
        AppBackground()
        SessionCard(draft: .constant(TodayView.DaySessionDraft(isTrainingDay: true, intensity: .normal, sessionType: nil,sessionStart: Date())), onSave: { print("save")})
    }
}
