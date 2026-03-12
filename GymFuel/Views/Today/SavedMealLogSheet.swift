import SwiftUI

struct SavedMealLogSheet: View {
    let meal: SavedMeal
    let selectedDate: Date
    let onLog: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date
    @State private var showTimePicker: Bool = false

    private let timePickerAnimation = Animation.easeInOut(duration: 0.35)

    init(meal: SavedMeal, selectedDate: Date, onLog: @escaping (Date) -> Void) {
        self.meal = meal
        self.selectedDate = selectedDate
        self.onLog = onLog
        _selectedTime = State(initialValue: Date())
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerRow

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Logging")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(displayTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    timePickerRow

                    Button {
                        let loggedAt = combine(date: selectedDate, time: selectedTime)
                        onLog(loggedAt)
                        dismiss()
                    } label: {
                        Text("Log meal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.liftEatsCoral, in: RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .presentationDetents([.medium])
    }

    private var headerRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline).bold()
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(Color(.systemBackground), in: Circle())
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Log saved meal")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    private var timePickerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: showTimePicker ? "x.circle" : "clock")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(.primary)

                Text("When did you eat this?")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(selectedTime, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if showTimePicker {
                DatePicker(
                    "",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .transition(.opacity.combined(with: .move(edge: .top)))

                Text("We use the time you had your meal to provide better insights with your fuel score.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(timePickerAnimation) {
                showTimePicker.toggle()
            }
        }
        .animation(timePickerAnimation, value: showTimePicker)
    }

    private var displayTitle: String {
        let trimmedName = meal.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = meal.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedName.isEmpty {
            return trimmedName
        }
        if !trimmedDescription.isEmpty {
            return trimmedDescription
        }
        return "Saved meal"
    }

    private func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? time
    }
}

#Preview {
    SavedMealLogSheet(
        meal: SavedMeal(
            id: UUID().uuidString,
            userId: "preview-user",
            name: "Chicken rice bowl",
            description: "Chicken, rice, avocado, and salsa",
            macros: Macros(calories: 620, protein: 45, carbs: 70, fat: 18)
        ),
        selectedDate: Date(),
        onLog: { _ in }
    )
}
