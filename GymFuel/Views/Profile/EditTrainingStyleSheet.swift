//
//  EditTrainingStyleSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 31/01/2026.
//

import SwiftUI

struct EditTrainingStyleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var trainingStyle: TrainingStyle?

    @State private var tempSelection: TrainingStyle = .strength
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.mixed.cardio")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)

            Text("Update this so Lift Eats can bias your fueling correctly (endurance and mixed training often need more carbs).")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                ForEach(TrainingStyle.allCases, id: \.self) { style in
                    Button {
                        tempSelection = style
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.displayName)
                                    .font(.headline)

                                Text(style.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if tempSelection == style {
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
                                    tempSelection == style ? Color.primary : Color.gray.opacity(0.3),
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
        .navigationTitle("Training Style")
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
                    trainingStyle = tempSelection
                    errorMessage = nil
                    dismiss()
                }  label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            if let existing = trainingStyle {
                tempSelection = existing
            }
        }
    }
}

#Preview {
    EditTrainingStyleSheet(trainingStyle: .constant(.mixed))
}
