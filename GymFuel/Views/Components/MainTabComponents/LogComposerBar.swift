import SwiftUI

/// The four logging targets at the bottom of the Day screen.
///
/// The shape, the shadows and the AX3 label-dropping all belong to `CircaDock`
/// — this type only names the four actions and owns the disabled state while a
/// submission is in flight.
struct LogActionDock: View {
    let isSubmitting: Bool
    let onCameraTap: () -> Void
    let onPhotoTap: () -> Void
    let onTextTap: () -> Void
    let onSavedMealsTap: () -> Void

    var body: some View {
        CircaDock(
            items: [
                CircaDockItem(title: "Text", systemName: "text.bubble", action: onTextTap),
                CircaDockItem(title: "Camera", systemName: "camera", action: onCameraTap),
                CircaDockItem(title: "Gallery", systemName: "photo.on.rectangle", action: onPhotoTap),
                CircaDockItem(title: "Saved", systemName: "bookmark", action: onSavedMealsTap)
            ],
            isDisabled: isSubmitting
        )
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
