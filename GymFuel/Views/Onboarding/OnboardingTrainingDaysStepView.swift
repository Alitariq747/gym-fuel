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
    @Environment(\.colorScheme) private var colorScheme
 
    let onNext: () -> Void
    
    @State private var selectedDays: Int = 3
    @State private var errorMessage: String?
    
    private let daysRange = Array(1...7)
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)
                
            
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
                .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
           
            
            Spacer()
            Button {
                handleNext()
            } label: {
                Text("Next")
                    .font(.headline).bold()
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
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
    OnboardingTrainingDaysStepView(trainingDaysPerWeek: .constant(2), onNext: { print("")})
}
