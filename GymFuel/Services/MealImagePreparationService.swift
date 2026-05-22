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
        maxDimension: CGFloat = 1024,
        minimumDimensionBeforeExtraCompression: CGFloat = 768,
        maxFileSizeBytes: Int = 1_500_000,
        compressionQuality: CGFloat = 0.70,
        minimumCompressionQuality: CGFloat = 0.60
    ) throws -> PreparedMealImage {
        guard let image = UIImage(data: originalData) else {
            throw MealImagePreparationError.invalidImageData
        }

        let compressedJPEGData = try compressImage(
            image,
            maxDimension: maxDimension,
            minimumDimensionBeforeExtraCompression: minimumDimensionBeforeExtraCompression,
            maxFileSizeBytes: maxFileSizeBytes,
            compressionQuality: compressionQuality,
            minimumCompressionQuality: minimumCompressionQuality
        )

        return PreparedMealImage(
            originalData: originalData,
            compressedJPEGData: compressedJPEGData
        )
    }

    private func compressImage(
        _ image: UIImage,
        maxDimension: CGFloat,
        minimumDimensionBeforeExtraCompression: CGFloat,
        maxFileSizeBytes: Int,
        compressionQuality: CGFloat,
        minimumCompressionQuality: CGFloat
    ) throws -> Data {
        var currentMaxDimension = maxDimension
        var smallestCompressedData: Data?

        while currentMaxDimension >= 320 {
            let resizedImage = resizeImage(image, maxDimension: currentMaxDimension)
            var currentQuality = compressionQuality

            while currentQuality >= minimumCompressionQuality {
                guard let compressedData = resizedImage.jpegData(compressionQuality: currentQuality) else {
                    throw MealImagePreparationError.compressionFailed
                }

                smallestCompressedData = compressedData

                if compressedData.count <= maxFileSizeBytes {
                    return compressedData
                }

                currentQuality -= 0.05
            }

            if currentMaxDimension <= minimumDimensionBeforeExtraCompression {
                currentMaxDimension *= 0.85
            } else {
                currentMaxDimension = max(minimumDimensionBeforeExtraCompression, currentMaxDimension * 0.85)
            }
        }

        guard let smallestCompressedData else {
            throw MealImagePreparationError.compressionFailed
        }

        return smallestCompressedData
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let pixelSize = CGSize(
            width: image.size.width * image.scale,
            height: image.size.height * image.scale
        )
        let longestSide = max(pixelSize.width, pixelSize.height)
        let scale = min(1, maxDimension / longestSide)
        let targetSize = CGSize(
            width: pixelSize.width * scale,
            height: pixelSize.height * scale
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
