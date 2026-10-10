//
//  PaywallPage.swift
//  GymFuel
//

import Foundation

/// The paywall's pages, in order. The trial page shows only when the selected
/// package has a free trial the person can take (build-order 15e).
enum PaywallPage: Equatable {
    case features, trial, plans

    static func sequence(hasTrial: Bool) -> [PaywallPage] {
        hasTrial ? [.features, .trial, .plans] : [.features, .plans]
    }

    func next(hasTrial: Bool) -> PaywallPage? {
        let pages = Self.sequence(hasTrial: hasTrial)
        guard let index = pages.firstIndex(of: self), index + 1 < pages.count else { return nil }
        return pages[index + 1]
    }

    func previous(hasTrial: Bool) -> PaywallPage? {
        let pages = Self.sequence(hasTrial: hasTrial)
        guard let index = pages.firstIndex(of: self), index > 0 else { return nil }
        return pages[index - 1]
    }
}
