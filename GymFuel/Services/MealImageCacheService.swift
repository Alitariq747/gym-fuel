import Foundation

struct MealImageCacheService {
    private let fileManager: FileManager
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func saveImageData(_ imageData: Data, entryId: String) throws {
        try fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
        try imageData.write(to: imageURL(for: entryId), options: .atomic)
        trimCacheIfNeeded()
    }

    func imageData(for entryId: String) -> Data? {
        try? Data(contentsOf: imageURL(for: entryId))
    }

    func deleteImageData(for entryId: String) {
        try? fileManager.removeItem(at: imageURL(for: entryId))
    }

    func trimCacheIfNeeded(maxSizeBytes: Int = 50 * 1024 * 1024) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else { return }
        let cachedFiles = files.map { url in
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            return (url, values?.fileSize ?? 0, values?.contentModificationDate ?? .distantPast)
        }.sorted { $0.2 < $1.2 }
        var totalSize = cachedFiles.reduce(0) { $0 + $1.1 }
        for cachedFile in cachedFiles where totalSize > maxSizeBytes {
            try? fileManager.removeItem(at: cachedFile.0)
            totalSize -= cachedFile.1
        }
    }

    private var cacheDirectoryURL: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MealImageCache", isDirectory: true)
    }

    private func imageURL(for entryId: String) -> URL { cacheDirectoryURL.appendingPathComponent("\(entryId).jpg") }
}
