import SwiftUI

struct SaveLoggedMealSheet: View {
    let initialName: String
    let initialDescription: String?
    let macros: Macros
    let isSaving: Bool
    let errorMessage: String?
    let onSave: (String, String?, Macros) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                            .foregroundStyle(Color.circaInk2)
                    }

                    VStack(spacing: 12) {
                        premiumField("fork.knife", title: "Meal name", text: $nameText, color: .circaInk)
                        premiumField("text.alignleft", title: "Pre-workout, breakfast, post-lift snack", text: $descriptionText, color: .circaInk2, lineLimit: 3...6)
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.circaDanger)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.circaDangerGround, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Macros", systemImage: "chart.bar.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.circaInk2)
                        macroField("Calories", symbol: "flame", text: $caloriesText)
                        macroField("Protein", symbol: "fish", text: $proteinText)
                        macroField("Carbs", symbol: "leaf", text: $carbsText)
                        macroField("Fat", symbol: "drop", text: $fatText)
                    }
                    .padding(16)
                    .background(Color.circaCard,
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
                }
                .padding(20)
            }
            .background(LinearGradient.circaPaper.ignoresSafeArea())
            .navigationTitle("Save Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.circaInk2)
                            .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                            .background(Color.circaWell, in: Circle())
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
                                    .tint(Color.circaPaperTop)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.bold))
                            }
                        }
                        .foregroundStyle(canSave ? Color.circaPaperTop : Color.circaInk3)
                        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                        .background(canSave ? Color.circaInk : Color.circaSunken, in: Circle())
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
                .background(Color.circaWell, in: Circle())
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
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func macroField(_ title: String, symbol: String, text: Binding<String>) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Image(systemName: symbol)
                .foregroundStyle(Color.circaInk2)
                .frame(width: 30, height: 30)
                .background(Color.circaWell, in: Circle())
            Text(title)
                .font(.subheadline.weight(.semibold))
            if !dynamicTypeSize.isAccessibilitySize { Spacer() }
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 74, alignment: .trailing)
        }
        .padding(12)
        .background(Color.circaSunken, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
