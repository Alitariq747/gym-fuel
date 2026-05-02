//
//  MealImageThumbnailView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 16/04/2026.
//

import SwiftUI
import UIKit

struct MealImageThumbnailView: View {
    let storagePath: String
    var size: CGFloat = 72
    var maxSizeBytes: Int64 = 2 * 1024 * 1024

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var didFail = false

    private let mealImageUploadService: MealImageUploadService

    init(
        storagePath: String,
        size: CGFloat = 72,
        maxSizeBytes: Int64 = 2 * 1024 * 1024,
        mealImageUploadService: MealImageUploadService = FirebaseMealImageUploadService()
    ) {
        self.storagePath = storagePath
        self.size = size
        self.maxSizeBytes = maxSizeBytes
        self.mealImageUploadService = mealImageUploadService
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
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
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task(id: storagePath) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard image == nil else { return }

        isLoading = true
        didFail = false

        do {
            let imageData = try await mealImageUploadService.fetchMealImageData(
                at: storagePath,
                maxSizeBytes: maxSizeBytes
            )
            guard let loadedImage = UIImage(data: imageData) else {
                didFail = true
                isLoading = false
                return
            }

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
