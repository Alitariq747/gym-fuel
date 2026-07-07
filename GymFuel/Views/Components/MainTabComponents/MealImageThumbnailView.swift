//
//  MealImageThumbnailView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 16/04/2026.
//

import SwiftUI
import UIKit

struct MealImageThumbnailView: View {
    let entryId: String?
    let storagePath: String?
    var size: CGFloat = 72
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var maxSizeBytes: Int64 = 2 * 1024 * 1024

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var didFail = false

    private let mealImageUploadService: MealImageUploadService

    init(
        entryId: String? = nil,
        storagePath: String? = nil,
        size: CGFloat = 72,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        maxSizeBytes: Int64 = 2 * 1024 * 1024,
        mealImageUploadService: MealImageUploadService = FirebaseMealImageUploadService()
    ) {
        self.entryId = entryId
        self.storagePath = storagePath
        self.size = size
        self.width = width
        self.height = height
        self.maxSizeBytes = maxSizeBytes
        self.mealImageUploadService = mealImageUploadService
    }

    var body: some View {
        Group {
            if let image {
                ZStack {
                    Color(.systemGray6)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width ?? size, height: height ?? size)
                        .clipped()
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray6))

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: didFail ? "photo" : "fork.knife")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(width: width ?? size, height: height ?? size)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task(id: "\(entryId ?? "")-\(storagePath ?? "")") {
            await loadImage()
        }
    }

    private func loadCachedImage() async -> UIImage? {
        guard let entryId else { return nil }
        let imageData = await Task.detached(priority: .utility) {
            MealImageCacheService().imageData(for: entryId)
        }.value
        return imageData.flatMap(UIImage.init(data:))
    }

    private func cacheImageData(_ imageData: Data) async {
        guard let entryId else { return }
        try? await Task.detached(priority: .utility) {
            try MealImageCacheService().saveImageData(imageData, entryId: entryId)
        }.value
    }

    private func loadImage() async {
        guard image == nil else { return }

        isLoading = true
        didFail = false

        do {
            if let cachedImage = await loadCachedImage() {
                image = cachedImage
                isLoading = false
                return
            }

            guard let storagePath else {
                didFail = true
                isLoading = false
                return
            }

            let imageData = try await mealImageUploadService.fetchMealImageData(
                at: storagePath,
                maxSizeBytes: maxSizeBytes
            )
            guard let loadedImage = UIImage(data: imageData) else {
                didFail = true
                isLoading = false
                return
            }

            await cacheImageData(imageData)
            image = loadedImage
            isLoading = false
        } catch {
            didFail = true
            isLoading = false
        }
    }
}

#Preview {
    MealImageThumbnailView(storagePath: "users/preview/mealImages/example.jpg")
        .padding()
}
