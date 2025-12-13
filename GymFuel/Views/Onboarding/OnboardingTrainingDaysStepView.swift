//
//  OnboardingTrainingDaysStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

/// Step: How many days per week do you *usually* train?
struct OnboardingTrainingDaysStepView: View {
    @Binding var trainingDaysPerWeek: Int?
    
    let onBack: () -> Void
    let onNext: () -> Void
    
    @State private var selectedDays: Int = 3
    @State private var errorMessage: String?
    
    private let daysRange = Array(1...7)
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your weekly training plan")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("How many days per week do you usually train? This helps us balance training and rest day fueling.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Training days per week")
                    .font(.headline)
                
                Picker("Training days per week", selection: $selectedDays) {
                    ForEach(daysRange, id: \.self) { day in
                        Text("\(day) day\(day == 1 ? "" : "s")")
                            .tag(day)
                    }
                }
                .pickerStyle(.wheel) // or .navigationLink / .menu if you prefer
                .frame(maxHeight: 150)
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                
                Button {
                    handleNext()
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Training Days")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    onBack()
                }
            }
        }
        .onAppear {
            if let existing = trainingDaysPerWeek, daysRange.contains(existing) {
                selectedDays = existing
            }
        }
    }
    
    private func handleNext() {
        guard daysRange.contains(selectedDays) else {
            errorMessage = "Please choose between 1 and 7 training days."
            return
        }
        
        errorMessage = nil
        trainingDaysPerWeek = selectedDays
        onNext()
    }
}


#Preview {
    OnboardingTrainingDaysStepView(trainingDaysPerWeek: .constant(2), onBack: { print("")}, onNext: { print("")})
}
