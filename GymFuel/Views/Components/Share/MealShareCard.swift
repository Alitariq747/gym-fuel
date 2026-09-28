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
        var explanation: String?
    }

    static let width: CGFloat = 360
    private static let photoWidth = width - 2 * Circa.Space.screenMargin
    private static let photoHeight = photoWidth * 9 / 16
    private static let markSize: CGFloat = 24

    let content: Content
    var photo: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.photoWidth, height: Self.photoHeight)
                    .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous))
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

            if let explanation = content.explanation {
                VStack(alignment: .leading, spacing: 6) {
                    CircaSectionLabel("How this was estimated")
                    Text(explanation)
                        .font(.caption)
                        .foregroundStyle(Color.circaInk)
                        .lineLimit(6)
                }
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

#Preview("Text meal") {
    MealShareCard(content: MealShareCard.Content(
        label: "Your words",
        title: "chicken stew, a cup of rice and a slice of bread",
        macros: Macros(calories: 665, protein: 37, carbs: 71, fat: 24),
        certainty: .estimated,
        explanation: "A home-style chicken stew, one bowl, with bone-in pieces simmered in onion and tomato. The rice is plain boiled white rice. The bread is one slice from a standard sandwich loaf."
    ))
}

#Preview("Photo meal") {
    let photo = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300)).image { context in
        UIColor.systemGray4.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
    }
    return MealShareCard(
        content: MealShareCard.Content(
            label: "Circa’s interpretation",
            title: "Scrambled eggs with toast and tea",
            macros: Macros(calories: 470, protein: 20, carbs: 36, fat: 27),
            certainty: .estimated,
            explanation: "Two eggs scrambled in a little butter. Two slices of white toast, each thinly buttered. Tea with a splash of whole milk and no sugar."
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
