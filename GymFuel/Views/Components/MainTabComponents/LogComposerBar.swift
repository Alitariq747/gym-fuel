import SwiftUI

struct LogActionDock: View {
    @Environment(\.colorScheme) private var colorScheme

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
        .background(dockBackgroundColor, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(dockStrokeColor, lineWidth: 1)
        }
        .shadow(color: dockShadowColor, radius: colorScheme == .dark ? 12 : 20, y: colorScheme == .dark ? 4 : 10)
        .opacity(isSubmitting ? 0.72 : 1)
        .disabled(isSubmitting)
    }

    private func dockButton(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.72))

                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.58))
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var dockBackgroundColor: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var dockStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    private var dockShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.22) : Color.black.opacity(0.12)
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
