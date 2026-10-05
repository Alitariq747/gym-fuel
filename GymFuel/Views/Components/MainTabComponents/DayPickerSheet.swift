import SwiftUI

struct DayPickerSheet: View {
    let onDone: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    init(date: Date, onDone: @escaping (Date) -> Void) {
        self.onDone = onDone
        _selectedDate = State(initialValue: date)
    }

    var body: some View {
        NavigationStack {
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(Color.circaAccent)
            .padding(.horizontal, Circa.Space.screenMargin)
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") { selectedDate = .now }
                        .foregroundStyle(Color.circaAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(Calendar.current.startOfDay(for: selectedDate))
                        dismiss()
                    }
                    .foregroundStyle(Color.circaAccent)
                }
            }
            .circaPaper()
        }
        .presentationDetents([.height(470), .large])
    }
}
