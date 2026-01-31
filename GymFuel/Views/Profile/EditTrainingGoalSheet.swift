//
//  EditTrainingGoalSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 31/01/2026.
//

import SwiftUI

struct EditTrainingGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var trainingGoal: TrainingGoal?

    @State private var tempSelection: TrainingGoal = .performance

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dot.scope")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Update your training goal so Lift Eats can keep your fueling targets aligned with your training.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                ForEach(TrainingGoal.allCases, id: \.self) { goal in
                    Button {
                        tempSelection = goal
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.displayName)
                                    .font(.headline)

                                Text(goal.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if tempSelection == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.primary)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.gray.opacity(0.3))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tempSelection == goal ? Color.primary : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Training Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss()
                } label: {
                    Image(systemName: "x.circle.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))

                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    trainingGoal = tempSelection
                    dismiss()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            if let existing = trainingGoal {
                tempSelection = existing
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditTrainingGoalSheet(trainingGoal: .constant(.fatLoss))
    }
}


