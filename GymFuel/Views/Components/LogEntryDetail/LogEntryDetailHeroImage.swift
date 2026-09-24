import SwiftUI

struct DetailHeroImage: View {
    let entry: LogEntry

    var body: some View {
        GeometryReader { geometry in
            MealImageThumbnailView(
                entryId: entry.id,
                storagePath: entry.image?.storagePath,
                width: geometry.size.width,
                height: geometry.size.width,
                displayMode: .fullPhoto
            )
            .overlay {
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                    .strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Meal photo")
    }
}
