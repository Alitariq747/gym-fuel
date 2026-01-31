//
//  EditTrainingTimeSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 31/01/2026.
//

import SwiftUI

struct EditTrainingTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var trainingTime: TrainingTimeOfDay?

    @State private var tempSelection: TrainingTimeOfDay = .evening
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {

            Image(systemName: "clock.circle")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text("Update this so Lift Eats can time your carbs and key meals around your workouts.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                ForEach(TrainingTimeOfDay.allCases, id: \.self) { time in
                    Button {
                        tempSelection = time
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(time.displayName)
                                    .font(.headline)
                                Text(time.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if tempSelection == time {
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
                                    tempSelection == time ? Color.primary : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Training Time")
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
                    trainingTime = tempSelection
                    errorMessage = nil
                    dismiss()
                }   label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))
                }
                .buttonStyle(.plain)

            }
        }
        .onAppear {
            if let existing = trainingTime {
                tempSelection = existing
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditTrainingTimeSheet(trainingTime: .constant(.evening))
    }
}

