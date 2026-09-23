import SwiftUI

struct DetailHeroImage: View {
    let entry: LogEntry

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            MealImageThumbnailView(
                entryId: entry.id,
                storagePath: entry.image?.storagePath,
                width: 250,
                height: 190
            )
            .background(Color.circaMediaWell, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.circaCardBorder, lineWidth: 6)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}
