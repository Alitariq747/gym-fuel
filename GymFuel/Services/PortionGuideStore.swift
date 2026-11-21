//
//  PortionGuideStore.swift
//  GymFuel
//

import Foundation

/// Holds the guide on screen: the copy last saved from the server, or the one
/// shipped in the app when there is none.
@MainActor
final class PortionGuideStore: ObservableObject {
    @Published private(set) var guide: PortionGuide

    private let service: PortionGuideService
    private let savedURL: URL

    nonisolated static var bundledData: Data? {
        Bundle.main.url(forResource: "portion-guide", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
    }

    nonisolated static var defaultSavedURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("portion-guide.json")
    }

    init(
        service: PortionGuideService = BackendPortionGuideService(),
        savedURL: URL = PortionGuideStore.defaultSavedURL,
        bundled: Data? = PortionGuideStore.bundledData
    ) {
        self.service = service
        self.savedURL = savedURL
        let saved = (try? Data(contentsOf: savedURL)).flatMap(PortionGuide.decode)
        guide = saved ?? bundled.flatMap(PortionGuide.decode) ?? .empty
    }

    /// A failed fetch, or a payload this build cannot show, changes nothing.
    func refresh() async {
        guard let data = try? await service.fetchGuideData(),
              let fetched = PortionGuide.decode(data),
              fetched.revision != guide.revision
        else { return }
        guide = fetched
        try? data.write(to: savedURL, options: .atomic)
    }
}
