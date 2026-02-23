//
//  MealImagePreprocessor.swift
//  GymFuel
//
//  Created by Codex on 21/02/2026.
//

import Foundation
import UIKit

struct ProcessedMealImage {
    let data: Data
    let mimeType: String
    let filename: String
}

protocol MealImagePreprocessing {
    func preprocess(_ image: UIImage) throws -> ProcessedMealImage
}

enum MealImagePreprocessorError: LocalizedError {
    case encodingFailed
    case imageTooLargeAfterCompression

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Couldn't prepare this image. Please try another photo."
        case .imageTooLargeAfterCompression:
            return "This image is too large to upload. Try a different photo."
        }
    }
}

struct MealImagePreprocessor: MealImagePreprocessing {
    let maxLongestEdgePixels: CGFloat
    let minLongestEdgePixels: CGFloat
    let maxUploadBytes: Int
    let initialCompressionQuality: CGFloat
    let minimumCompressionQuality: CGFloat
    let compressionStep: CGFloat
    let downscaleFactor: CGFloat

    init(
        maxLongestEdgePixels: CGFloat = 1280,
        minLongestEdgePixels: CGFloat = 640,
        maxUploadBytes: Int = 900 * 1024,
        initialCompressionQuality: CGFloat = 0.82,
        minimumCompressionQuality: CGFloat = 0.45,
        compressionStep: CGFloat = 0.08,
        downscaleFactor: CGFloat = 0.85
    ) {
        self.maxLongestEdgePixels = maxLongestEdgePixels
        self.minLongestEdgePixels = minLongestEdgePixels
        self.maxUploadBytes = maxUploadBytes
        self.initialCompressionQuality = initialCompressionQuality
        self.minimumCompressionQuality = minimumCompressionQuality
        self.compressionStep = compressionStep
        self.downscaleFactor = downscaleFactor
    }

    func preprocess(_ image: UIImage) throws -> ProcessedMealImage {
        let normalized = normalizeOrientation(of: image)
        var working = resizeIfNeeded(normalized, maxLongestEdge: maxLongestEdgePixels)
        var currentLongestEdge = longestEdge(of: working)
        var bestData: Data?

        while true {
            guard let compressed = compressJPEG(working) else {
                throw MealImagePreprocessorError.encodingFailed
            }

            bestData = selectSmallerData(bestData, compressed)

            if compressed.count <= maxUploadBytes {
                return ProcessedMealImage(
                    data: compressed,
                    mimeType: "image/jpeg",
                    filename: "meal.jpg"
                )
            }

            guard currentLongestEdge > minLongestEdgePixels else {
                break
            }

            currentLongestEdge = max(
                minLongestEdgePixels,
                floor(currentLongestEdge * downscaleFactor)
            )
            working = resizeImage(working, longestEdge: currentLongestEdge)
        }

        guard let finalData = bestData else {
            throw MealImagePreprocessorError.encodingFailed
        }

        if finalData.count > maxUploadBytes {
            throw MealImagePreprocessorError.imageTooLargeAfterCompression
        }

        return ProcessedMealImage(
            data: finalData,
            mimeType: "image/jpeg",
            filename: "meal.jpg"
        )
    }
}

private extension MealImagePreprocessor {
    func compressJPEG(_ image: UIImage) -> Data? {
        var quality = initialCompressionQuality
        var lastData: Data?

        while quality >= minimumCompressionQuality {
            guard let data = image.jpegData(compressionQuality: quality) else {
                return nil
            }

            lastData = data
            if data.count <= maxUploadBytes {
                return data
            }

            quality -= compressionStep
        }

        return lastData
    }

    func resizeIfNeeded(_ image: UIImage, maxLongestEdge: CGFloat) -> UIImage {
        let longest = longestEdge(of: image)
        guard longest > maxLongestEdge else { return image }
        return resizeImage(image, longestEdge: maxLongestEdge)
    }

    func resizeImage(_ image: UIImage, longestEdge: CGFloat) -> UIImage {
        let originalSize = pixelSize(of: image)
        let oldLongest = max(originalSize.width, originalSize.height)
        guard oldLongest > 0 else { return image }

        let ratio = longestEdge / oldLongest
        let targetSize = CGSize(
            width: max(1, floor(originalSize.width * ratio)),
            height: max(1, floor(originalSize.height * ratio))
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func normalizeOrientation(of image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let size = pixelSize(of: image)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func longestEdge(of image: UIImage) -> CGFloat {
        let size = pixelSize(of: image)
        return max(size.width, size.height)
    }

    func pixelSize(of image: UIImage) -> CGSize {
        if let cgImage = image.cgImage {
            return CGSize(width: cgImage.width, height: cgImage.height)
        }

        return CGSize(
            width: max(1, image.size.width * image.scale),
            height: max(1, image.size.height * image.scale)
        )
    }

    func selectSmallerData(_ existing: Data?, _ candidate: Data) -> Data {
        guard let existing else { return candidate }
        return candidate.count < existing.count ? candidate : existing
    }
}
