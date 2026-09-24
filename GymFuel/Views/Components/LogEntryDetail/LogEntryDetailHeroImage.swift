import SwiftUI

struct DetailHeroImage: View {
    let entry: LogEntry

    var body: some View {
        GeometryReader { geometry in
            MealImageThumbnailView(
                entryId: entry.id,
                storagePath: entry.image?.storagePath,
                width: geometry.size.width,
                height: 168
            )
        }
        .frame(height: 168)
        .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous))
        .accessibilityLabel("Meal photo")
    }
}
