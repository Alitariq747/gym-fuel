//
//  TodayView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

// TodayView.swift
// GymFuel

import SwiftUI


struct TodayView: View {
    @ObservedObject var viewModel: DayLogViewModel
    @Binding var selectedDate: Date
    
   @State private var showAddMealFlow = false
    @State private var selectedMeal: Meal?
    
    struct DaySessionDraft {
        var isTrainingDay: Bool
        var intensity: TrainingIntensity?
        var sessionType: SessionType?
        var sessionStart: Date
    }
    
    private func makeSessionDraft(from log: DayLog) -> DaySessionDraft {
        DaySessionDraft(
             isTrainingDay: log.isTrainingDay,
             intensity: log.trainingIntensity,
             sessionType: log.sessionType,
             sessionStart: log.sessionStart
                 ?? viewModel.defaultSessionStart(for: log.date)
                 ?? Date()
         )
    }
    
    @State private var isSessionSheetPresented = false
    @State private var sessionDraft = DaySessionDraft(
        isTrainingDay: true,
        intensity: .normal,
        sessionType: nil,
        sessionStart: Date()
    )
        
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
    
   
    var body: some View {
      
        ZStack {
            // HStack for top row
            AppBackground()
            
            ScrollView {
                VStack(spacing: 14) {
                    
                    // HStack for title and icon
                    HStack(alignment: .center) {
                        Image("LiftEatsWelcomeIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("Lift Eats")
                            .font(.system(size: 28, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                DateStripView(selectedDate: $selectedDate)
                if let msg = viewModel.errorMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                
                if let log = viewModel.dayLog {
                    
                    Button {
                        
                        sessionDraft = makeSessionDraft(from: log)
                        isSessionSheetPresented = true
                    } label: {
                        SessionSummaryCard(dayLog: log)
                    }
                    .buttonStyle(.plain)
                    
                    MetricsPagerSection(dayLog: log, consumed: viewModel.consumedMacros)
                    
                   Text("Fuel TimeLine")
                    
                    
//                    MealsListSection(dayLog: log, meals: viewModel.meals) { meal in
//                        selectedMeal = meal
//                    }
                } else {
                    ProgressView()
                }
            }
                
        }
            .padding()
            
            VStack {
                Spacer()
                HStack {
                  
                    Spacer()
                    Button {
                        showAddMealFlow = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title).bold()
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.black, in: Circle())
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 8,
                                x: 0, y: 4
                            )
                    }
                   
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
            }
            

            
        }
        .sheet(isPresented: $isSessionSheetPresented) {
            SessionEditSheet(draft: $sessionDraft) {
                Task {
                    await applySessionDraftAndSave()
                    isSessionSheetPresented = false
                }
            } onCancel: {
                isSessionSheetPresented = false
            }

        }

        .sheet(isPresented: $showAddMealFlow, content: {
            AddMealFlowSheet(dayLogViewModel: viewModel, dayDate: selectedDate)
        })
        .onAppear {
            Task { await viewModel.createOrLoadTodayLog(date: selectedDate) }
        }
        .onChange(of: selectedDate) { _, newDate in
            Task { await viewModel.createOrLoadTodayLog(date: newDate) }
        }
        .overlay {
            if viewModel.isLoading && viewModel.dayLog == nil {
                ProgressView("Loading your day…")
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
      
        .sheet(item: $selectedMeal) { meal in
            MealDetailSheet(meal: meal) { editedMeal in
                Task {
                    await viewModel.updateMeal(editedMeal)
                }
                selectedMeal = nil

            } onDelete: {
                Task {
                    await viewModel.removeMeal(meal)
                }
                selectedMeal = nil
            }

        }
    }
    @MainActor
    private func applySessionDraftAndSave() async {
        viewModel.setIsTrainingDay(sessionDraft.isTrainingDay)
        if sessionDraft.isTrainingDay {
            viewModel.setSessionType(sessionDraft.sessionType)
            viewModel.setSessionStart(sessionDraft.sessionStart)
            viewModel.setTrainingIntensity(sessionDraft.intensity)
        }
        
        await viewModel.saveCurrentDayLog()
    }

}





#Preview {
  
       
        TodayView(viewModel: DayLogViewModel(profile: dummyProfile), selectedDate: .constant(Date()))
    
}

