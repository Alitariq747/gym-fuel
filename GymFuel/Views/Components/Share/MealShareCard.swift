import SwiftUI

/// One meal, drawn to be rendered as an image — `design.md`, *Share card (7k)*.
/// Takes plain values the detail sheet already works out, so the card and the
/// screen cannot disagree about a title or a provenance line.
struct MealShareCard: View {
    struct Content {
        let label: String
        let title: String
        let macros: Macros
        let certainty: CircaCertainty
        var provenance: String?
        var breakdown: MealShareBreakdown?
    }

    static let width: CGFloat = 360
    private static let photoSide: CGFloat = 192
    private static let markSize: CGFloat = 24

    let content: Content
    var photo: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let photo {
                let shape = RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                MealFullPhoto(image: photo, width: Self.photoSide, height: Self.photoSide)
                    .clipShape(shape)
                    .overlay { shape.strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline) }
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 6) {
                CircaSectionLabel(content.label)
                Text(verbatim: content.title)
                    .font(.headline)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            nutrition

            if let provenance = content.provenance {
                Text(provenance)
                    .font(.circaMono)
                    .foregroundStyle(Color.circaAccent)
            }

            if let breakdown = content.breakdown {
                breakdownList(breakdown)
            }

            footer
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.top, 24)
        .padding(.bottom, 18)
        .frame(width: Self.width, alignment: .leading)
        .background(LinearGradient.circaPaper)
    }

    /// The four numbers in one row, calories first and largest. Labels share a
    /// baseline so the row reads straight across whatever the numbers' sizes.
    private var nutrition: some View {
        CircaCard(inset: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                figure(
                    MealCopy.calories(content.macros), unit: nil, glyph: .calories, name: "kcal",
                    font: .system(size: Circa.Display.shareTotal, weight: .semibold, design: .monospaced)
                )
                .fixedSize()
                .padding(.trailing, 4)
                figure(MealCopy.grams(content.macros.protein), unit: "g", glyph: .protein, name: "Protein")
                figure(MealCopy.grams(content.macros.carbs), unit: "g", glyph: .carbs, name: "Carbs")
                figure(MealCopy.grams(content.macros.fat), unit: "g", glyph: .fat, name: "Fat")
            }
        }
    }

    private func figure(
        _ number: String?, unit: String?, glyph: CircaMacroGlyph.Macro, name: String, font: Font = .circaMonoLarge
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                CircaEstimate(number, certainty: content.certainty, font: font)
                if let unit {
                    Text(unit).font(.circaMono).foregroundStyle(Color.circaInk3)
                }
            }
            HStack(spacing: 3) {
                CircaInlineGlyph(glyph)
                Text(name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Color.circaInk2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func breakdownList(_ breakdown: MealShareBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            CircaSectionLabel("Breakdown")
            VStack(spacing: 8) {
                ForEach(Array(breakdown.rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { CircaHairline(weight: .inCard) }
                    breakdownRow(
                        row.name, amount: MealCopy.amount(row.amount), macros: row.macros,
                        certainty: row.source == .estimated ? .estimated : .known
                    )
                }
                if breakdown.moreCount > 0 {
                    CircaHairline(weight: .inCard)
                    breakdownRow(
                        MealCopy.Share.more(breakdown.moreCount), amount: nil, macros: breakdown.moreMacros,
                        certainty: content.certainty, nameColor: .circaInk2
                    )
                }
            }
        }
    }

    /// One line, whatever the meal: the name gives way so the amount and the number never do.
    private func breakdownRow(
        _ name: String, amount: String?, macros: Macros?, certainty: CircaCertainty, nameColor: Color = .circaInk
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(verbatim: name)
                .font(.circaBody)
                .foregroundStyle(nameColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let amount {
                Text(verbatim: amount)
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
                    .fixedSize()
            }
            if let calories = MealCopy.calories(macros) {
                CircaEstimate(calories, certainty: certainty)
                    .fixedSize()
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            CircaHairline()
            HStack {
                HStack(spacing: 7) {
                    Image("CircaMark")
                        .resizable()
                        .frame(width: Self.markSize, height: Self.markSize)
                    Text(MealCopy.Share.name)
                        .font(.circaRow.weight(.semibold))
                        .foregroundStyle(Color.circaInk)
                }
                Spacer(minLength: 8)
                CircaSectionLabel(MealCopy.Share.footnote)
            }
        }
    }
}

private func previewBreakdown(_ items: [(String, Double, String, Double)]) -> MealShareBreakdown? {
    MealShareBreakdown(MealBreakdown(items: items.map { name, quantity, unit, calories in
        MealItem(
            id: name, name: name, amount: MealAmount(quantity: quantity, unit: unit),
            nutrition: Macros(calories: calories, protein: 0, carbs: 0, fat: 0)
        )
    }))
}

#Preview("Text meal") {
    MealShareCard(content: MealShareCard.Content(
        label: "Your words",
        title: "rice, chicken stew, lentils, a flatbread, yogurt, salad and tea",
        macros: Macros(calories: 1060, protein: 52, carbs: 128, fat: 36),
        certainty: .estimated,
        breakdown: previewBreakdown([
            ("White rice, boiled", 1, "plate", 310), ("Chicken stew", 1, "bowl", 340),
            ("Lentils", 1, "bowl", 180), ("Flatbread", 1, "piece", 120), ("Yogurt", 3, "tbsp", 45),
            ("Salad", 1, "small plate", 25), ("Tea with milk", 1, "cup", 40)
        ])
    ))
}

#Preview("Photo meal") {
    let photo = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400)).image { context in
        UIColor.systemGray4.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
    }
    return MealShareCard(
        content: MealShareCard.Content(
            label: "Circa’s interpretation",
            title: "Scrambled eggs with toast and tea",
            macros: Macros(calories: 470, protein: 20, carbs: 36, fat: 27),
            certainty: .estimated,
            breakdown: previewBreakdown([
                ("Scrambled eggs", 2, "eggs", 200), ("White toast, buttered", 2, "slice", 230),
                ("Tea with milk", 1, "cup", 40)
            ])
        ),
        photo: photo
    )
}

#Preview("Typed totals") {
    MealShareCard(content: MealShareCard.Content(
        label: "Your words",
        title: "two eggs and toast",
        macros: Macros(calories: 400, protein: 20, carbs: 30, fat: 22),
        certainty: .known,
        provenance: "You set this total"
    ))
}
