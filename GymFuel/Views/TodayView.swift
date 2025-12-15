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
    @State private var showEditSessionSheet: Bool = false
    
    @State private var showSettings = false
    @State private var showHistory = false
    
    struct DaySessionDraft {
        var isTrainingDay: Bool
        var intensity: TrainingIntensity?
        var sessionType: SessionType?
        var sessionStart: Date
    }
    
    @State private var draft = DaySessionDraft(isTrainingDay: false, intensity: nil, sessionType: nil, sessionStart: Date())
    
    private func openEditSheet(from log: DayLog) {
        draft.isTrainingDay = log.isTrainingDay
        draft.intensity = log.trainingIntensity
        draft.sessionType = log.sessionType
        draft.sessionStart = log.sessionStart ?? (viewModel.defaultSessionStart(for: log.date) ?? Date())
        showEditSessionSheet = true
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    
    var body: some View {
        ZStack {
            // HStack for top row
            ScrollView {
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
                }

                if let log = viewModel.dayLog {
                    if log.isTrainingDay {
                        TrainingCard(sessionStart: log.sessionStart, intensity: log.trainingIntensity, sessionType: log.sessionType, onEdit: { openEditSheet(from: log) })
                            .padding(.top, 8)
                    } else {
                        RestDayCard(onEdit: { openEditSheet(from: log) })
                            .padding(.top, 8)
                    }
                    MacroCardsSection(targets: log.macroTargets, consumed: viewModel.consumedMacros)
                } else {
                    CardSkeleton()
                    MacroCardsSection(targets: .zero, consumed: .zero)
                }
            }
            .padding()
            // We'll  later add the HStack for button to open sheet and my fuel card
        }
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
        .sheet(isPresented: $showEditSessionSheet) {
            EditSessionSheet(draft: $draft) {
                Task {
                    viewModel.setIsTrainingDay(draft.isTrainingDay)
                    
                    if draft.isTrainingDay {
                        viewModel.setSessionType(draft.sessionType)
                        viewModel.setSessionStart(draft.sessionStart)
                        viewModel.setTrainingIntensity(draft.intensity)
                    }
                    await viewModel.saveCurrentDayLog()
                    showEditSessionSheet = false
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }

    }

}





#Preview {
    ZStack {
        AppBackground()
        TodayView(viewModel: DayLogViewModel(profile: dummyProfile), selectedDate: .constant(Date()))
    }
}

