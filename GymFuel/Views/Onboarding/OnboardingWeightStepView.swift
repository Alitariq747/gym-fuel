//
//  OnboardingWeightStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

private enum WeightUnit: String, CaseIterable {
    case kilograms
    case pounds
}

/// Step 4: Ask for the user's weight.
struct OnboardingWeightStepView: View {
    @Binding var weightKg: Double?      // stored in kilograms
    
    let onBack: () -> Void
    let onNext: () -> Void
    
    @State private var selectedUnit: WeightUnit = .kilograms
    @State private var kgText: String = ""
    @State private var lbsText: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Last step!")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("Your weight helps us calculate accurate macros for your training.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Picker("Unit", selection: $selectedUnit) {
                Text("kg").tag(WeightUnit.kilograms)
                Text("lbs").tag(WeightUnit.pounds)
            }
            .pickerStyle(.segmented)
            
            Group {
                switch selectedUnit {
                case .kilograms:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg)")
                            .font(.headline)
                        TextField("e.g. 75", text: $kgText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                case .pounds:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (lbs)")
                            .font(.headline)
                        TextField("e.g. 165", text: $lbsText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
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
        .navigationTitle("Your Weight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    onBack()
                }
            }
        }
        .onAppear {
            // If we already have weight in kg, prefill the kg field
            if let current = weightKg, kgText.isEmpty, lbsText.isEmpty {
                kgText = String(format: "%.1f", current)
            }
        }
    }
    
    private func handleNext() {
        let computedKg: Double?
        
        switch selectedUnit {
        case .kilograms:
            guard let kg = Double(kgText), kg > 0 else {
                errorMessage = "Please enter a valid weight in kilograms."
                return
            }
            computedKg = kg
            
        case .pounds:
            guard let lbs = Double(lbsText), lbs > 0 else {
                errorMessage = "Please enter a valid weight in pounds."
                return
            }
            computedKg = lbs * 0.453592
        }
        
        errorMessage = nil
        weightKg = computedKg
        onNext()
    }
}


#Preview {
    OnboardingWeightStepView(weightKg: .constant(78.50), onBack: { print("")}, onNext: {print("")})
}
