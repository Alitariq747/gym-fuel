//
//  OnboardingGenderStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingGenderStepView: View {
    let name: String
    @Binding var gender: String
    
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
                  Text("Great.\(name)")
                      .font(.title.bold())
                      .multilineTextAlignment(.center)
                  
                  Text("Now select your gender.")
                      .font(.body)
                      .foregroundStyle(.secondary)
                      .multilineTextAlignment(.center)
                  
                  VStack(alignment: .leading, spacing: 8) {
                      Text("Gender")
                          .font(.headline)
                      
                      Picker("Gender", selection: $gender) {
                          Text("Male").tag("Male")
                          Text("Female").tag("Female")
                      }
                      .pickerStyle(.segmented)
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
              .navigationTitle("Your Gender")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  // Optional: back button in the nav bar as well
                  ToolbarItem(placement: .topBarLeading) {
                      Button("Back") {
                          onBack()
                      }
                  }
              }    }
    
    private func handleNext() {
        guard !gender.isEmpty else {
            errorMessage = "Please select a gender."
            return
        }
        errorMessage = nil
        onNext()
    }
}

