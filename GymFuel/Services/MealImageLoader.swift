import UIKit

/// A meal's photo: the copy on this device first, then Storage, keeping what it
/// downloaded for next time.
@MainActor
struct MealImageLoader {
    nonisolated static let defaultMaxSizeBytes: Int64 = 2 * 1024 * 1024

    private let uploadService: MealImageUploadService

    init(uploadService: MealImageUploadService = FirebaseMealImageUploadService()) {
        self.uploadService = uploadService
    }

    /// `nil` when neither has a usable image.
    func image(entryId: String?, storagePath: String?, maxSizeBytes: Int64) async -> UIImage? {
        if let entryId, let cached = await cachedImageData(for: entryId).flatMap(UIImage.init(data:)) {
            return cached
        }

        guard let storagePath,
              let imageData = try? await uploadService.fetchMealImageData(at: storagePath, maxSizeBytes: maxSizeBytes),
              let image = UIImage(data: imageData)
        else { return nil }

        if let entryId {
            await cache(imageData, for: entryId)
        }
        return image
    }

    private func cachedImageData(for entryId: String) async -> Data? {
        await Task.detached(priority: .utility) {
            MealImageCacheService().imageData(for: entryId)
        }.value
    }

    private func cache(_ imageData: Data, for entryId: String) async {
        try? await Task.detached(priority: .utility) {
            try MealImageCacheService().saveImageData(imageData, entryId: entryId)
        }.value
    }
}
