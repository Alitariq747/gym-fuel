//
//  AddMealFlowSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 17/12/2025.
//

import SwiftUI

import SwiftUI

struct AddMealFlowSheet: View {
    @ObservedObject var dayLogViewModel: DayLogViewModel
    let dayDate: Date

    @Environment(\.dismiss) private var dismissSheet

    @StateObject private var addMealViewModel = AddMealViewModel(
        service: BackendMealParsingService(
            baseURL: URL(string: "http://localhost:5001")!
        )
    )

    @State private var pendingDescription: String = ""
    @State private var pendingParsed: ParsedMeal?
    @State private var pendingMealTime: Date = Date()
    @State private var showReview: Bool = false

    var body: some View {
       
           
            NavigationStack {
                // STEP 1: description screen
                AddMealSheet(
                    viewModel: addMealViewModel,
                    dayDate: dayDate
                ) { description in
                    // Save what the user typed
                    pendingDescription = description
                    pendingMealTime = combine(date: dayDate, time: Date())
                    pendingParsed = nil
                    addMealViewModel.errorMessage = nil
                    
                    // Immediately move to the "review" destination
                    showReview = true
                    
                    // Kick off the async parsing
                    addMealViewModel.descriptionText = description
                    
                    Task {
                        await addMealViewModel.parse()
                        
                        // When parsing finishes, copy result into our pendingParsed.
                        await MainActor.run {
                            pendingParsed = addMealViewModel.parsed
                        }
                    }
                }
                // STEP 2: destination – first shows loader, then review sheet.
                .navigationDestination(isPresented: $showReview) {
                    ZStack {
                        AppBackground()
                    if let parsed = pendingParsed {
                        // Parsed data is available: show review UI
                        ReviewMealSheet(
                            originalDescription: pendingDescription,
                            parsed: parsed,
                            mealTime: pendingMealTime
                        ) { finalDescription, finalParsed, finalTime in
                            Task {
                                await dayLogViewModel.addMealAi(
                                    originalDescription: finalDescription,
                                    parsedMeal: finalParsed,
                                    loggedAt: finalTime
                                )
                            }
                            // Close whole flow after saving
                            dismissSheet()
                        } onDiscard: {
                            showReview = false
                            dismissSheet()
                        }
                    } else {
                        // Still parsing OR it failed
                        VStack(spacing: 16) {
                            if let error = addMealViewModel.errorMessage {
                                MealParsingErrorView(message: error) {
                                    showReview = false
                                    pendingParsed = nil
                                    addMealViewModel.errorMessage = nil
                                }
                                
                                
                            } else {
                                MealParsingLoadingView()
                            }
                        }
                        .padding()
                    }
                }
                .navigationBarBackButtonHidden(true)
                }
               
            }
            .toolbar(.hidden, for: .navigationBar)
        
    }

    private func combine(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps = cal.dateComponents([.hour, .minute], from: time)
        comps.hour = timeComps.hour
        comps.minute = timeComps.minute
        return cal.date(from: comps) ?? date
    }
}

#Preview {
    AddMealFlowSheet(dayLogViewModel: DayLogViewModel(profile: dummyProfile), dayDate: Date())
}
