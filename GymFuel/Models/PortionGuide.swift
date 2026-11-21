//
//  PortionGuide.swift
//  GymFuel
//
//  The portion guide the server builds from its food table. The payload and its
//  rules are in `meal-contract.md` §11.
//

import Foundation

struct GuideCategory: Codable, Equatable, Hashable, Sendable, Identifiable {
    var id: String
    var name: String
}

struct GuideContainer: Codable, Equatable, Hashable, Sendable, Identifiable {
    var id: String
    var name: String
    var kind: String
    var cups: Double
    var ml: Double
    var inches: Double?
}

struct GuideSpoon: Codable, Equatable, Hashable, Sendable, Identifiable {
    var id: String
    var name: String
    var ml: Double
}

struct GuideFatLevel: Codable, Equatable, Hashable, Sendable, Identifiable {
    var id: String
    var name: String
    var tbspPerPlate: Double
    var looks: String?
}

struct GuideAmount: Codable, Equatable, Hashable, Sendable, Identifiable {
    var label: String
    var grams: Double

    var id: String { label }
}

/// A weighed photo at `/guide-images/<image>.jpg`. `grams` is nil for a photo of
/// several sizes with the weights printed on it.
struct GuidePhoto: Codable, Equatable, Hashable, Sendable {
    var image: String
    var grams: Double?
}

/// Weights only: the guide never shows calories or macros (§11).
struct GuideFood: Codable, Equatable, Hashable, Sendable, Identifiable {
    var id: String
    var name: String
    var category: String
    var thumbnail: String?
    var pieceName: String?
    var note: String?
    var photos: [GuidePhoto]?
    var amounts: [GuideAmount]
}

struct GuideSection: Equatable, Identifiable {
    var category: GuideCategory
    var foods: [GuideFood]

    var id: String { category.id }
}

struct PortionGuide: Equatable, Sendable {
    static let supportedVersion = 1
    static let empty = PortionGuide(
        version: supportedVersion, revision: "", source: nil, credit: nil,
        categories: [], containers: [], spoons: [], fatLevels: [], foods: []
    )

    var version: Int
    var revision: String
    var source: String?
    var credit: String?
    var categories: [GuideCategory]
    var containers: [GuideContainer]
    var spoons: [GuideSpoon]
    var fatLevels: [GuideFatLevel]
    var foods: [GuideFood]

    /// Foods in the server's category order. A food under a category the payload
    /// does not list gets a group of its own rather than being hidden.
    var sections: [GuideSection] {
        var groups = categories
        for food in foods where !groups.contains(where: { $0.id == food.category }) {
            groups.append(GuideCategory(id: food.category, name: food.category.capitalized))
        }
        return groups.compactMap { category in
            let members = foods.filter { $0.category == category.id }
            return members.isEmpty ? nil : GuideSection(category: category, foods: members)
        }
    }
}

extension PortionGuide: Decodable {
    private enum CodingKeys: String, CodingKey {
        case version, revision, source, credit, categories, containers, spoons, fatLevels, foods
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        revision = try container.decode(String.self, forKey: .revision)
        source = try? container.decodeIfPresent(String.self, forKey: .source)
        credit = try? container.decodeIfPresent(String.self, forKey: .credit)
        categories = container.readable(.categories)
        containers = container.readable(.containers)
        spoons = container.readable(.spoons)
        fatLevels = container.readable(.fatLevels)
        foods = container.readable(.foods)
    }

    /// Nil for a payload this build should not show: unreadable, a newer
    /// `version`, or no foods. The caller keeps the guide it already has.
    static func decode(_ data: Data) -> PortionGuide? {
        guard let guide = try? JSONDecoder().decode(PortionGuide.self, from: data),
              guide.version <= supportedVersion,
              !guide.foods.isEmpty
        else { return nil }
        return guide
    }
}

private extension KeyedDecodingContainer {
    /// One entry this build cannot read is skipped, not fatal: the server adds
    /// foods and sizes without an app release.
    func readable<T: Codable & Equatable & Hashable & Sendable>(_ key: Key) -> [T] {
        ((try? decode([Lenient<T>].self, forKey: key)) ?? []).compactMap(\.wrappedValue)
    }
}
