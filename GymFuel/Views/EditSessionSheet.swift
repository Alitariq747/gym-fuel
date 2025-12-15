//
//  EditSessionSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//

import SwiftUI

struct EditSessionSheet: View {
    @Binding var draft: TodayView.DaySessionDraft
    @Environment(\.dismiss) private var dismiss
    
    private func hapticSoft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }


        let onSave: () -> Void

        var body: some View {
            NavigationStack {
                ZStack {
                    AppBackground()
                    Form {
                        Section {
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
                            
                        }
                        
                        Section("Session") {
                            Picker("Intensity", selection: $draft.intensity) {
                                Text("Not set").tag(TrainingIntensity?.none)
                                ForEach(TrainingIntensity.allCases, id: \.self) { i in
                                    Text(i.rawValue.capitalized).tag(Optional(i))
                                }
                            }
                            
                            
                            Picker("Type", selection: $draft.sessionType) {
                                Text("Not set").tag(SessionType?.none)
                                ForEach(SessionType.allCases, id: \.self) { t in
                                    Text(t.rawValue.capitalized).tag(Optional(t))
                                }
                            }
                            
                            
                            DatePicker("Workout time", selection: $draft.sessionStart, displayedComponents: [.hourAndMinute])
                        }
                        .disabled(!draft.isTrainingDay)
                        .opacity(draft.isTrainingDay ? 1 : 0.5)
                        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: draft.isTrainingDay)
                        
                    }
                    .scrollContentBackground(.hidden)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "x.circle")
                                    .foregroundStyle(Color.liftEatsCoral)
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                hapticSuccess()
                                onSave()
                                dismiss()
                            } label: {
                                Text("Save")
                                    .foregroundStyle(Color.indigo)
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
}

#Preview {
    EditSessionSheet(draft: .constant(TodayView.DaySessionDraft(isTrainingDay: true, sessionStart: Date())), onSave: { print("save")})
}
