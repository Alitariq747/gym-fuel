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
    var maxSizeBytes: Int64 = MealImageLoader.defaultMaxSizeBytes

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var didFail = false

    private let loader: MealImageLoader

    init(
        entryId: String? = nil,
        storagePath: String? = nil,
        size: CGFloat = 72,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        displayMode: DisplayMode = .thumbnail,
        maxSizeBytes: Int64 = MealImageLoader.defaultMaxSizeBytes,
        mealImageUploadService: MealImageUploadService = FirebaseMealImageUploadService()
    ) {
        self.entryId = entryId
        self.storagePath = storagePath
        self.size = size
        self.width = width
        self.height = height
        self.displayMode = displayMode
        self.maxSizeBytes = maxSizeBytes
        self.loader = MealImageLoader(uploadService: mealImageUploadService)
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
                        MealFullPhoto(image: image, width: width ?? size, height: height ?? size)
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

    private func loadImage() async {
        guard image == nil else { return }

        isLoading = true
        didFail = false
        image = await loader.image(entryId: entryId, storagePath: storagePath, maxSizeBytes: maxSizeBytes)
        didFail = image == nil
        isLoading = false
    }
}

/// The whole photo, never cropped, its blurred copy filling the rest of the frame.
/// The Entry screen and the share card both draw it, so the two cannot differ.
struct MealFullPhoto: View {
    let image: UIImage
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Color.circaMediaWell

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .blur(radius: 18)
                .opacity(0.55)
                .clipped()
                .accessibilityHidden(true)

            Color.circaMediaWell.opacity(0.25)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
        }
        .frame(width: width, height: height)
    }
}

#Preview {
    MealImageThumbnailView(storagePath: "users/preview/mealImages/example.jpg")
        .padding()
}
