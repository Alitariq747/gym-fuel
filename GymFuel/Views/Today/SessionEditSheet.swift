//
//  SessionEditSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/01/2026.
//

import SwiftUI

struct SessionEditSheet: View {
    @Binding var draft: TodayView.DaySessionDraft

    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var showTimePicker = false

    private let timePickerAnimation = Animation.spring(
        response: 0.28,
        dampingFraction: 0.9
    )

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                // Top bar: close + title + save
                HStack {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .padding(8)
                            .foregroundStyle(Color.indigo)
                            .background(Color.white.opacity(0.9), in: Circle())
                            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }

                    Spacer()

                    Text("Set Session")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        onSave()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .padding(8)
                            .foregroundStyle(Color.indigo)
                            .background(Color.white.opacity(0.9), in: Circle())
                            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 18) {

                        // MAIN CARD
                        VStack(alignment: .leading, spacing: 18) {

                            Text("SESSION")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)

                            Text(draft.isTrainingDay ? "Training day" : "Rest day")
                                .font(.title3.weight(.semibold))

                            // Training vs Rest toggle pill
                            trainingToggle

                            // Only show details when it's a training day
                            if draft.isTrainingDay {
                                VStack(alignment: .leading, spacing: 14) {

                                    // Intensity
                                    Menu {
                                        Button("Not set") { draft.intensity = nil }
                                        ForEach(TrainingIntensity.allCases, id: \.self) { intensity in
                                            Button(intensity.rawValue.capitalized) {
                                                draft.intensity = intensity
                                            }
                                           
                                        }
                                    } label: {
                                        headerFieldRow(
                                            systemImage: "flame.fill",
                                            title: "Intensity",
                                            value: intensityLabel,
                                          
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    // Session type
                                    Menu {
                                        Button("Not set") { draft.sessionType = nil }
                                        ForEach(SessionType.allCases, id: \.self) { t in
                                            Button(t.rawValue.capitalized) {
                                                draft.sessionType = t
                                            }
                                        }
                                    } label: {
                                        headerFieldRow(
                                            systemImage: "dumbbell.fill",
                                            title: "Session type",
                                            value: typeLabel
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    // Time picker toggle
                                    Button {
                                        withAnimation(timePickerAnimation) {
                                            showTimePicker.toggle()
                                        }
                                    } label: {
                                        headerFieldRow(
                                            systemImage: "clock.fill",
                                            title: "Workout time",
                                            value: timeLabel
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    if showTimePicker {
                                        DatePicker(
                                            "",
                                            selection: $draft.sessionStart,
                                            displayedComponents: [.hourAndMinute]
                                        )
                                        .labelsHidden()
                                        .datePickerStyle(.wheel)
                                        .frame(maxWidth: .infinity)
                                        .transition(
                                            .move(edge: .top)
                                            .combined(with: .opacity)
                                        )
                                    }
                                }
                            } else {
                                // Rest-day helper text
                                Text("This is a rest day. We’ll ease off your carb targets and focus on recovery.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.9))
                        )
                        .shadow(color: Color.black.opacity(0.12),
                                radius: 10, x: 0, y: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
    }


    private var trainingToggle: some View {
        HStack(spacing: 4) {
            toggleChip(
                title: "Training",
                systemImage: "bolt.fill",
                isSelected: draft.isTrainingDay
            ) {
                setTrainingDay(true)
            }

            toggleChip(
                title: "Rest",
                systemImage: "bed.double.fill",
                isSelected: !draft.isTrainingDay
            ) {
                setTrainingDay(false)
            }
        }
    }

    private func toggleChip(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.indigo.opacity(0.9) : Color(.systemGray6))
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func setTrainingDay(_ isTraining: Bool) {
        draft.isTrainingDay = isTraining

        if !isTraining {
            draft.intensity = nil
            draft.sessionType = nil
        } else if draft.intensity == nil {
            draft.intensity = .normal
        }
    }


    private func headerFieldRow(
        systemImage: String,
        title: String,
        value: String,
        badge: some View = EmptyView()
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            badge

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.9))
        )
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
    SessionEditSheet(
        draft: .constant(
            TodayView.DaySessionDraft(
                isTrainingDay: true,
                intensity: .normal,
                sessionType: nil,
                sessionStart: Date()
            )
        ),
        onSave: { print("Save") },
        onCancel: { print("Cancel") }
    )
}
