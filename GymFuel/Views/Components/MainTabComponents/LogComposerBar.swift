import SwiftUI

struct LogActionDock: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let isSubmitting: Bool
    let onCameraTap: () -> Void
    let onPhotoTap: () -> Void
    let onTextTap: () -> Void
    let onSavedMealsTap: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            dockButton(title: "Text", systemName: "text.bubble", action: onTextTap)
            dockButton(title: "Camera", systemName: "camera", action: onCameraTap)
            dockButton(title: "Gallery", systemName: "photo.on.rectangle", action: onPhotoTap)
            dockButton(title: "Saved", systemName: "bookmark", action: onSavedMealsTap)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.circaCard, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.circaCardBorder, lineWidth: 1)
        }
        .opacity(isSubmitting ? 0.72 : 1)
        .disabled(isSubmitting)
    }

    private func dockButton(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.circaInk)

                if !dynamicTypeSize.isAccessibilitySize {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.circaInk2)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

}

#Preview {
    LogActionDock(
        isSubmitting: false,
        onCameraTap: {},
        onPhotoTap: {},
        onTextTap: {},
        onSavedMealsTap: {}
    )
    .padding()
}
