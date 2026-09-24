import SwiftUI

struct MealPhotoPanel<Content: View>: View {
    let isReviewing: Bool
    let isDismissing: Bool
    let onClose: () -> Void
    let onDismissed: () -> Void
    @ViewBuilder let content: () -> Content
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var isMounted = false

    private let margin: CGFloat = 12
    private var animation: Animation { .easeInOut(duration: reduceMotion ? 0.15 : 0.25) }

    var body: some View {
        GeometryReader { geometry in
            let width = max(0, geometry.size.width - margin * 2)
            let availableHeight = max(0, geometry.size.height - margin * 2)
            let height = isReviewing && typeSize.isAccessibilitySize
                ? availableHeight : min(width * 4 / 3, availableHeight)
            ZStack(alignment: .bottom) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { if !isDismissing { onClose() } }
                    .accessibilityHidden(true)
                VStack(spacing: isReviewing ? 12 : 0) {
                    if isReviewing { reviewHeader }
                    content()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(isReviewing ? Circa.Space.screenMargin : 0)
                .frame(width: width, height: height)
                .background {
                    if isReviewing { LinearGradient.circaPaper }
                    else { Color(white: 0.12) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 18, y: 4)
                .scaleEffect(isVisible || reduceMotion ? 1 : 0.94, anchor: .bottom)
                .opacity(isVisible ? 1 : 0)
                .allowsHitTesting(!isDismissing)
                .accessibilityHidden(isDismissing)
                .padding(.bottom, margin)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
        .onAppear {
            isMounted = true
            withAnimation(animation) { isVisible = true }
        }
        .onDisappear { isMounted = false }
        .onChange(of: isDismissing) { _, closing in
            guard closing else { return }
            withAnimation(animation, completionCriteria: .removed) {
                isVisible = false
            } completion: {
                if isMounted { onDismissed() }
            }
        }
    }

    private var reviewHeader: some View {
        HStack(spacing: 12) {
            CircaSectionLabel("Meal photo")
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(.body).weight(.medium))
                    .foregroundStyle(Color.circaInk2)
                    .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

struct MealPhotoControlLabel: View {
    var symbol: String?
    var title: String?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 8) {
            if let symbol { Image(systemName: symbol) }
            if let title { Text(title) }
        }
        .font(.system(.body).weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, title == nil ? 0 : 16)
        .frame(minWidth: Circa.minHitTarget, minHeight: Circa.minHitTarget)
        .background {
            if reduceTransparency { Capsule().fill(Color(white: 0.16)) }
            else { Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark) }
        }
        .overlay { Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5) }
        .contentShape(Capsule())
    }
}
