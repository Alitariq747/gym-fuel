//
//  EditTrainingExperienceSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 31/01/2026.
//

import SwiftUI


struct EditTrainingExperienceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var trainingExperience: TrainingExperience?

    @State private var tempSelection: TrainingExperience = .beginner

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.stairs")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text("Update this so Lift Eats can adjust how aggressive it is with deficits and surpluses without hurting performance.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(TrainingExperience.allCases, id: \.self) { level in
                    Button {
                        tempSelection = level
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.displayName)
                                    .font(.headline)

                                Text(level.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if tempSelection == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.primary)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(Color.gray.opacity(0.3))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    tempSelection == level ? Color.primary : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Training Experience")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss()
                } label: {
                    Image(systemName: "x.circle.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))

                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    trainingExperience = tempSelection
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
            if let existing = trainingExperience {
                tempSelection = existing
            }
        }
    }
}


#Preview {
    EditTrainingExperienceSheet(trainingExperience: .constant(.intermediate))
}
