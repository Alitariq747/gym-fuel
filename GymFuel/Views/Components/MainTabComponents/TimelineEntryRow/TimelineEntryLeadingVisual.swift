import SwiftUI

struct TimelineEntryLeadingVisual: View {
    let entry: LogEntry
    let state: TimelineEntryRowState
    let width: CGFloat
    let height: CGFloat


    private let symbolCircleSize: CGFloat = 46

    var body: some View {
        content
            .frame(width: width, height: height, alignment: .center)
    }

    @ViewBuilder
    private var content: some View {
        if let localPreviewData = state.localPreviewData,
           let previewImage = UIImage(data: localPreviewData) {
            mealImageVisual {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
            }
        } else if state.isMealImageEntry {
            mealImageVisual {
                MealImageThumbnailView(
                    entryId: entry.id,
                    storagePath: state.imageStoragePath,
                    width: width,
                    height: height
                )
            }
        } else if !state.isAnalyzingTextEntry {
            leadingSymbol(entry.source == .savedMeal ? "bookmark" : "square.and.pencil")
        }
    }

    private func mealImageVisual<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                if state.isAnalyzingImageEntry {
                    ImageAnalysisScannerOverlay()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
    }

    private func leadingSymbol(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(Color.circaInk)
            .frame(width: symbolCircleSize, height: symbolCircleSize)
            .background(Color.circaWell, in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.circaCardBorder, lineWidth: 1)
            }
    }
}

private struct ImageAnalysisScannerOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isScanning = false

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let scannerWidth = max(width * 0.28, 18)

            ZStack(alignment: .leading) {
                Color.clear

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.26),
                                Color.white.opacity(0.18),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: scannerWidth)
                    .offset(x: reduceMotion ? width * 0.36 : (isScanning ? width : -scannerWidth))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            isScanning = false
            withAnimation(.easeInOut(duration: 1.55).repeatForever(autoreverses: false)) {
                isScanning = true
            }
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled {
                isScanning = false
            }
        }
    }
}
