import Foundation

enum LogAttachmentSource: String, Equatable, Sendable {
    case camera
    case photoLibrary
}

struct LogComposerDraft: Equatable, Sendable {
    var text: String = ""
    var imageData: Data?
    var attachmentSource: LogAttachmentSource?

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasContent: Bool {
        !trimmedText.isEmpty || imageData != nil
    }
}
