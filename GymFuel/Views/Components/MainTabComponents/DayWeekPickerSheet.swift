import SwiftUI

enum DayWeekScale: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"

    var id: Self { self }
}

struct DayWeekPickerSheet: View {
    let onApply: (Date, DayWeekScale) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    @State private var scale: DayWeekScale

    init(date: Date, scale: DayWeekScale, onApply: @escaping (Date, DayWeekScale) -> Void) {
        self.onApply = onApply
        _selectedDate = State(initialValue: date)
        _scale = State(initialValue: scale)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("View", selection: $scale) {
                        ForEach(DayWeekScale.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker(
                        "Jump to date",
                        selection: $selectedDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.circaAccent)
                    .padding(12)
                    .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.card))

                    CircaCard(.sunken) {
                        Text("Older days can be read. You can log only today and the previous seven days.")
                            .font(.circaBody)
                    }

                    Button {
                        onApply(Calendar.current.startOfDay(for: selectedDate), scale)
                        dismiss()
                    } label: {
                        Text("Show \(scale.rawValue.lowercased())")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.circa(.primary, height: 52))
                }
                .padding(Circa.Space.screenMargin)
            }
            .navigationTitle("Choose a date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.circaAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Today") { selectedDate = .now }
                        .foregroundStyle(Color.circaAccent)
                }
            }
            .circaPaper()
        }
        .presentationDetents([.large])
    }
}
