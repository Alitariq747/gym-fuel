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
    
    @State private var showDatePicker: Bool = false
    
    @State private var showSettings = false
    @State private var showHistory = false
    
   @State private var showAddMealFlow = false
    
    struct DaySessionDraft {
        var isTrainingDay: Bool
        var intensity: TrainingIntensity?
        var sessionType: SessionType?
        var sessionStart: Date
    }
    
    @State private var draft = DaySessionDraft(isTrainingDay: false, intensity: nil, sessionType: nil, sessionStart: Date())
    
    private func syncDraft(from log: DayLog) {
        draft.isTrainingDay = log.isTrainingDay
        draft.intensity = log.trainingIntensity
        draft.sessionType = log.sessionType
        draft.sessionStart = log.sessionStart
            ?? (viewModel.defaultSessionStart(for: log.date) ?? Date())
    }

    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    
    var body: some View {
      
        ZStack {
            // HStack for top row
            AppBackground()
            
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                    Image("LiftEatsWelcomeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                    
                    Spacer()
                    Button {
                        showDatePicker = true
                    } label: {
                        Text(formattedDate(selectedDate))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(.white))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                if let msg = viewModel.errorMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                
                if let log = viewModel.dayLog {
                    
                   
                    SessionCard(
                        draft: $draft
                    ) {
                        // onSave from inside the card → push changes into viewModel
                        Task {
                            viewModel.setIsTrainingDay(draft.isTrainingDay)
                            
                            if draft.isTrainingDay {
                                viewModel.setSessionType(draft.sessionType)
                                viewModel.setSessionStart(draft.sessionStart)
                                viewModel.setTrainingIntensity(draft.intensity)
                            }
                            await viewModel.saveCurrentDayLog()
                        }
                    }
                    .padding(.top, 8)
                    .onAppear {
                       
                        syncDraft(from: log)
                    }
                    MacroCardsSection(targets: log.macroTargets, consumed: viewModel.consumedMacros)
                    
                    HStack {
                        Text("Logged Nutrition")
                            .font(.headline).bold()
                            .foregroundStyle(.black.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(viewModel.meals.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(10)
                            .background(Color.white.opacity(0.85), in: Circle())
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 8,
                                x: 0, y: 4
                            )
                    }
                    
                    
                    MealsListSection(dayLog: log, meals: viewModel.meals)
                } else {
                    ProgressView()
                }
                Button {
                    showAddMealFlow = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Log meal with AI")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                            .shadow(radius: 4, y: 2)
                    )
                }
                .padding(.top, 16)
            }
        }
            .padding()
            // We'll  later add the HStack for button to open sheet and my fuel card
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
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Spacer()
                }
                .navigationTitle("Pick a day")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showDatePicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .overlay {
            if viewModel.isLoading && viewModel.dayLog == nil {
                ProgressView("Loading your day…")
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
 
    }

}





#Preview {
  
       
        TodayView(viewModel: DayLogViewModel(profile: dummyProfile), selectedDate: .constant(Date()))
    
}

