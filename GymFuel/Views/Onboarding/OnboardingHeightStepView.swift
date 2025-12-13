//
//  OnboardingHeightStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

private enum HeightUnit: String, CaseIterable {
    case centimeters
    case feetInches
}

struct OnboardingHeightStepView: View {
    
    @Binding var heightCm: Double?
    
    let onBack: () -> Void
    let onNext: () -> Void
    
    @State private var selectedUnit: HeightUnit = .centimeters
    @State private var cmText: String = ""
    @State private var feetText: String = ""
    @State private var inchesText: String = ""
    @State private var errorMessage: String?

    
    var body: some View {
            VStack(spacing: 24) {
                Text("Almost done!")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                
                Text("Tell us your height so we can better estimate your fueling needs.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Unit picker
                Picker("Unit", selection: $selectedUnit) {
                    Text("cm").tag(HeightUnit.centimeters)
                    Text("ft / in").tag(HeightUnit.feetInches)
                }
                .pickerStyle(.segmented)
                
                // Inputs depending on unit
                Group {
                    switch selectedUnit {
                    case .centimeters:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Height (cm)")
                                .font(.headline)
                            TextField("e.g. 175", text: $cmText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                    case .feetInches:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Height (ft / in)")
                                .font(.headline)
                            
                            HStack {
                                TextField("ft", text: $feetText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("in", text: $inchesText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
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
            .navigationTitle("Your Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        onBack()
                    }
                }
            }
        }
        
        private func handleNext() {
            let computedCm: Double?
            
            switch selectedUnit {
            case .centimeters:
                guard let cm = Double(cmText), cm > 0 else {
                    errorMessage = "Please enter a valid height in centimeters."
                    return
                }
                computedCm = cm
                
            case .feetInches:
                let feet = Double(feetText) ?? 0
                let inches = Double(inchesText) ?? 0
                
                guard feet > 0 || inches > 0 else {
                    errorMessage = "Please enter a valid height in feet and inches."
                    return
                }
                
                let totalInches = feet * 12 + inches
                let cm = totalInches * 2.54
                computedCm = cm
            }
            
            errorMessage = nil
            heightCm = computedCm
            onNext()
        }
    }
#Preview {
    OnboardingHeightStepView(heightCm: .constant(123.45), onBack: {print("")}, onNext: {print("")})
}
