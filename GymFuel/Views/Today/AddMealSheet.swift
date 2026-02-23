//
//  AddMealSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 16/12/2025.
//

import SwiftUI

struct AddMealSheet: View {
    @ObservedObject var viewModel: AddMealViewModel
    let dayDate: Date

    /// Called when the user has entered a valid description
    /// and wants to continue to AI parsing.
    let onNext: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        ZStack {
            AppBackground()
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    viewModel.reset()
                    dismiss()
                    
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline).bold()
                        .foregroundStyle(Color(.systemGray))
                        .padding(10)
                        .background(Color(.systemBackground), in: Circle())
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    
                }
                .padding()
                
                // 1) Description input
                ZStack(alignment: .top) {
                    
                    if (viewModel.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        VStack {
                            Text("DESCRIBE YOUR MEAL BY TEXT")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("""
                        Write what you ate in your own words. For example: \
                        "2 slices of whole wheat bread with peanut butter and a banana. Be very precise to get better results."
                        """)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        
                    }
                    
                    TextEditor(text: $viewModel.descriptionText)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    
                    
                    
                }
                .padding(.horizontal, 16)
                // 2) Error, if any
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                // 3) Continue button (no parsing here)
                Button {
                    let input = viewModel.descriptionText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard !input.isEmpty else {
                        
                        viewModel.errorMessage = "Please describe your meal."
                        return
                    }
                    
                    onNext(input)
                } label: {
                    Text("Estimate macros with AI")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    viewModel.descriptionText
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .isEmpty
                                    ? Color.gray.opacity(0.3)
                                    : Color.liftEatsCoral
                                )
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .disabled(
                    viewModel.descriptionText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                )
                
                Spacer()
            }
        }
         
        
    }
}

#Preview {
    AddMealSheet(
        viewModel: AddMealViewModel(
            service: BackendMealParsingService(
                baseURL: URL(string: "http://localhost:5001")!
            )
        ),
        dayDate: Date()
    ) { _ in
        print("Next")
    }
}

