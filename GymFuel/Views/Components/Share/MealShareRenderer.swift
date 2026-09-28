import SwiftUI

/// The share card as an image: 3×, always light and at one text size, so every
/// card looks the same whoever sends it — `design.md`, *Share card (7k)*.
@MainActor
enum MealShareRenderer {
    static func image(of card: MealShareCard) -> UIImage? {
        let renderer = ImageRenderer(content: card
            .environment(\.colorScheme, .light)
            .environment(\.dynamicTypeSize, .large))
        renderer.scale = 3
        return renderer.uiImage
    }
}
