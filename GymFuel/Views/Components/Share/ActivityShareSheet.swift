import LinkPresentation
import SwiftUI

/// The system share sheet, presented from wherever this sits. Used instead of
/// `ShareLink` because it reports how the share ended, and 7k counts completed
/// shares.
struct ActivityShareSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]
    /// Where it went, or `nil` when nothing was sent.
    let onFinish: (UIActivity.ActivityType?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        guard isPresented, host.presentedViewController == nil else { return }

        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { activityType, completed, _, _ in
            isPresented = false
            onFinish(completed ? activityType : nil)
        }
        host.present(controller, animated: true)
    }
}

/// An image the share sheet can title. Without link metadata, iOS heads the
/// sheet with the app icon and no words.
final class ShareImageItem: NSObject, UIActivityItemSource {
    let image: UIImage
    let title: String

    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)
        metadata.iconProvider = metadata.imageProvider
        return metadata
    }
}
