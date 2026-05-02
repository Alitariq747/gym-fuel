import CoreGraphics
import Foundation
import UIKit

struct PreparedMealImage: Sendable {
    let originalData: Data
    let compressedJPEGData: Data
}

enum MealImagePreparationError: LocalizedError {
    case invalidImageData
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "We couldn't load that photo. Please try another image."
        case .compressionFailed:
            return "We couldn't prepare that photo. Please try a different image."
        }
    }
}

struct MealImagePreparationService {
    func prepareImageData(
        from originalData: Data,
        maxDimension: CGFloat = 1600,
        compressionQuality: CGFloat = 0.75
    ) throws -> PreparedMealImage {
        guard let image = UIImage(data: originalData) else {
            throw MealImagePreparationError.invalidImageData
        }

        let longestSide = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / longestSide)
        let targetSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let compressedJPEGData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw MealImagePreparationError.compressionFailed
        }

        return PreparedMealImage(
            originalData: originalData,
            compressedJPEGData: compressedJPEGData
        )
    }
}
