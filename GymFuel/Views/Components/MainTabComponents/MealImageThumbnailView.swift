//
//  MealImageThumbnailView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 16/04/2026.
//

import SwiftUI
import UIKit

struct MealImageThumbnailView: View {
    enum DisplayMode {
        case thumbnail
        case fullPhoto
    }

    let entryId: String?
    let storagePath: String?
    var size: CGFloat = 72
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var displayMode: DisplayMode = .thumbnail
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
        displayMode: DisplayMode = .thumbnail,
        maxSizeBytes: Int64 = 2 * 1024 * 1024,
        mealImageUploadService: MealImageUploadService = FirebaseMealImageUploadService()
    ) {
        self.entryId = entryId
        self.storagePath = storagePath
        self.size = size
        self.width = width
        self.height = height
        self.displayMode = displayMode
        self.maxSizeBytes = maxSizeBytes
        self.mealImageUploadService = mealImageUploadService
    }

    var body: some View {
        Group {
            if let image {
                ZStack {
                    Color.circaMediaWell

                    switch displayMode {
                    case .thumbnail:
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: width ?? size, height: height ?? size)
                            .clipped()
                    case .fullPhoto:
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: width ?? size, height: height ?? size)
                            .blur(radius: 18)
                            .opacity(0.55)
                            .clipped()
                            .accessibilityHidden(true)

                        Color.circaMediaWell.opacity(0.25)

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: width ?? size, height: height ?? size)
                    }
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.circaMediaWell)

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: didFail ? "photo" : "fork.knife")
                            .font(.title3)
                            .foregroundStyle(Color.circaInk2)
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
