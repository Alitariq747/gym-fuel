import SwiftUI

struct SaveLoggedMealSheet: View {
    let initialName: String
    let initialDescription: String?
    let macros: Macros
    let isSaving: Bool
    let errorMessage: String?
    let onSave: (String, String?, Macros) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nameText: String
    @State private var descriptionText: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String

    init(
        initialName: String,
        initialDescription: String?,
        macros: Macros,
        isSaving: Bool = false,
        errorMessage: String? = nil,
        onSave: @escaping (String, String?, Macros) -> Void
    ) {
        self.initialName = initialName
        self.initialDescription = initialDescription
        self.macros = macros
        self.isSaving = isSaving
        self.errorMessage = errorMessage
        self.onSave = onSave
        _nameText = State(initialValue: initialName)
        _descriptionText = State(initialValue: initialDescription ?? "")
        _caloriesText = State(initialValue: "\(Int(macros.calories.rounded()))")
        _proteinText = State(initialValue: "\(Int(macros.protein.rounded()))")
        _carbsText = State(initialValue: "\(Int(macros.carbs.rounded()))")
        _fatText = State(initialValue: "\(Int(macros.fat.rounded()))")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Save this meal")
                            .font(.title3.weight(.bold))
                        Text("Tune the name and macros before it goes into saved meals.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        premiumField("fork.knife", title: "Meal name", text: $nameText, color: .fuelOrange)
                        premiumField("text.alignleft", title: "Pre-workout, breakfast, post-lift snack", text: $descriptionText, color: .fuelBlue, lineLimit: 3...6)
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.fuelRed)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.fuelRed.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Macros", systemImage: "chart.bar.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        macroField("Calories", emoji: "🔥", text: $caloriesText, color: .fuelOrange)
                        macroField("Protein", emoji: "💪", text: $proteinText, color: .fuelBlue)
                        macroField("Carbs", emoji: "⚡️", text: $carbsText, color: .fuelGreen)
                        macroField("Fat", emoji: "💧", text: $fatText, color: .pink)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
                }
                .padding(20)
            }
            .navigationTitle("Save Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.fuelRed)
                            .frame(width: 34, height: 34)
                            .background(Color.fuelRed.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let description = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(nameText, description.isEmpty ? nil : description, editedMacros)
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.bold))
                            }
                        }
                        .foregroundStyle(canSave ? Color.white : Color.secondary)
                        .frame(width: 34, height: 34)
                        .background(canSave ? Color.fuelGreen : Color(.tertiarySystemFill), in: Circle())
                        .shadow(color: Color.fuelGreen.opacity(canSave ? 0.24 : 0), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private func premiumField(_ systemImage: String, title: String, text: Binding<String>, color: Color, lineLimit: ClosedRange<Int>? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: Circle())
            Group {
                if let lineLimit {
                    TextField(title, text: text, axis: .vertical)
                        .lineLimit(lineLimit)
                } else {
                    TextField(title, text: text, axis: .vertical)
                }
            }
            .font(.subheadline.weight(.medium))
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func macroField(_ title: String, emoji: String, text: Binding<String>, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: Circle())
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline.weight(.bold))
                .frame(width: 74)
        }
        .padding(12)
        .background(Color(.systemBackground).opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: color.opacity(0.08), radius: 10, y: 5)
        .shadow(color: Color.black.opacity(0.035), radius: 6, y: 3)
    }

    private var editedMacros: Macros {
        Macros(
            calories: Double(caloriesText) ?? 0,
            protein: Double(proteinText) ?? 0,
            carbs: Double(carbsText) ?? 0,
            fat: Double(fatText) ?? 0
        )
    }

    private var canSave: Bool {
        let hasName = !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let macros = editedMacros
        return hasName && (macros.calories > 0 || macros.protein > 0 || macros.carbs > 0 || macros.fat > 0)
    }
}
#Preview {
    SaveLoggedMealSheet(
        initialName: "Chicken rice bowl",
        initialDescription: "Chicken, rice, avocado, and salsa",
        macros: Macros(calories: 620, protein: 45, carbs: 70, fat: 18),
        onSave: { _, _, _ in }
    )
}
