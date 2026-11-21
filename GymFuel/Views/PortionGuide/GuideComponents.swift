//
//  GuideComponents.swift
//  GymFuel
//

import SwiftUI

/// A guide photo, loaded from the server and never bundled, so a deploy can swap it
/// (§11). The server's 30-day cache header keeps a seen photo on the phone. The
/// glyph shows until it loads, when it cannot, and for a food with no photo.
struct GuideImage: View {
    let image: String?
    var contentMode: ContentMode = .fill

    static func url(for image: String, base: URL = AppConfig.backendBaseURL) -> URL {
        base.appendingPathComponent("guide-images").appendingPathComponent("\(image).jpg")
    }

    var body: some View {
        Color.circaMediaWell
            .overlay {
                if let image {
                    AsyncImage(url: Self.url(for: image)) { phase in
                        if let photo = phase.image {
                            photo.resizable().aspectRatio(contentMode: contentMode)
                        } else {
                            glyph
                        }
                    }
                } else {
                    glyph
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private var glyph: some View {
        Image(systemName: "fork.knife")
            .font(.circaRow)
            .foregroundStyle(Color.circaInk3)
    }
}

/// A section label over a card of rows, with hairlines between them.
struct GuideRowsCard<Item: Identifiable, Row: View>: View {
    let title: String
    let items: [Item]
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CircaSectionLabel(title)
            CircaCard(inset: EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)) {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 { CircaHairline(weight: .inCard) }
                        row(item)
                    }
                }
            }
        }
    }
}

/// The server's numbers as words, rounded for reading only: no portion maths (§11).
enum GuideFormat {
    static func size(of container: GuideContainer, locale: Locale = .autoupdatingCurrent) -> String {
        var parts: [String] = []
        if let inches = container.inches {
            parts.append("\(inches.formatted(.number.locale(locale))) in")
        }
        let cups = container.cups.formatted(.number.precision(.fractionLength(0...2)).locale(locale))
        parts.append("\(cups) \(container.cups == 1 ? "cup" : "cups")")
        parts.append(ml(container.ml, locale: locale))
        return parts.joined(separator: " · ")
    }

    /// One decimal under 10 g, where whole grams would blur a teaspoon.
    static func grams(_ grams: Double, locale: Locale = .autoupdatingCurrent) -> String {
        let digits: ClosedRange<Int> = grams < 10 ? 0...1 : 0...0
        return "\(grams.formatted(.number.precision(.fractionLength(digits)).locale(locale))) g"
    }

    static func ml(_ ml: Double, locale: Locale = .autoupdatingCurrent) -> String {
        "\(ml.formatted(.number.precision(.fractionLength(0)).locale(locale))) ml"
    }

    static func oil(_ level: GuideFatLevel, locale: Locale = .autoupdatingCurrent) -> String {
        "\(level.tbspPerPlate.formatted(.number.precision(.fractionLength(0...2)).locale(locale))) tbsp a plate"
    }
}
