//
//  PortionGuideTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import Circa

enum GuideFixture {
    static let rice = """
    {"id":"rice_cooked","name":"White rice","category":"grains","thumbnail":"rice_cooked-191g",
     "pieceName":null,"note":"Cooked weight.",
     "photos":[{"image":"rice_cooked-54g","grams":54},{"image":"rice_cooked-191g","grams":191}],
     "amounts":[{"label":"A plate","grams":316}]}
    """
    static let samosa = """
    {"id":"samosa","name":"Samosa","category":"snacks",
     "amounts":[{"label":"One samosa","grams":60}]}
    """
    static let unreadable = #"{"id":"mystery","name":"Mystery","category":"grains"}"#

    static func payload(version: Int = 1, revision: String = "r1", foods: [String] = [rice]) -> Data {
        Data("""
        {"version":\(version),"revision":"\(revision)","source":"USDA FoodData Central",
         "credit":"Photos: Intake24 (intake24.org).",
         "categories":[{"id":"grains","name":"Rice, pasta and bread"},{"id":"fruit","name":"Fruit"}],
         "containers":[{"id":"plate","name":"Plate","kind":"plate","cups":2,"ml":473,"inches":10},{"id":"odd"}],
         "fatLevels":[{"id":"normal","name":"Normal","tbspPerPlate":1,"looks":"A light gloss."}],
         "foods":[\(foods.joined(separator: ","))]}
        """.utf8)
    }
}

@Suite("PortionGuide")
struct PortionGuideTests {
    @Test func theBundledGuideDecodes() throws {
        let data = try #require(PortionGuideStore.bundledData)
        let guide = try #require(PortionGuide.decode(data))
        #expect(guide.foods.count >= 30)
        #expect(guide.containers.contains { $0.id == "plate" && $0.inches == 10 })
        #expect(guide.fatLevels.count == 5)
        #expect(guide.sections.map(\.category.id) == guide.categories.map(\.id))
        #expect(guide.credit?.contains("Intake24") == true)

        let rice = try #require(guide.foods.first { $0.id == "rice_cooked" })
        #expect(rice.amounts.first { $0.label == "A plate" }?.grams == 316)
        #expect(rice.photos?.map(\.grams) == [54, 101, 191, 359])
        let roti = try #require(guide.foods.first { $0.id == "roti" })
        #expect(roti.photos == [GuidePhoto(image: "roti", grams: nil)])
    }

    @Test func anEntryThisBuildCannotReadIsSkipped() throws {
        let guide = try #require(PortionGuide.decode(
            GuideFixture.payload(foods: [GuideFixture.unreadable, GuideFixture.rice])
        ))
        #expect(guide.foods.map(\.id) == ["rice_cooked"])
        #expect(guide.containers.map(\.id) == ["plate"])
        #expect(guide.spoons.isEmpty)
    }

    @Test func aNewerVersionOrAnEmptyGuideIsRefused() {
        #expect(PortionGuide.decode(GuideFixture.payload(version: 2)) == nil)
        #expect(PortionGuide.decode(GuideFixture.payload(foods: [GuideFixture.unreadable])) == nil)
        #expect(PortionGuide.decode(Data("not json".utf8)) == nil)
    }

    @Test func aFoodUnderAnUnlistedCategoryIsStillShown() throws {
        let guide = try #require(PortionGuide.decode(
            GuideFixture.payload(foods: [GuideFixture.samosa, GuideFixture.rice])
        ))
        #expect(guide.sections.map(\.category.id) == ["grains", "snacks"])
        #expect(guide.sections.last?.category.name == "Snacks")
        #expect(guide.sections.last?.foods.map(\.id) == ["samosa"])
    }

    @Test func aFoodReadsWithOrWithoutPhotos() throws {
        let guide = try #require(PortionGuide.decode(
            GuideFixture.payload(foods: [GuideFixture.rice, GuideFixture.samosa])
        ))
        #expect(guide.credit == "Photos: Intake24 (intake24.org).")
        #expect(guide.foods[0].photos?.map(\.image) == ["rice_cooked-54g", "rice_cooked-191g"])
        #expect(guide.foods[0].thumbnail == "rice_cooked-191g")
        #expect(guide.foods[1].photos == nil)
        #expect(guide.foods[1].amounts.map(\.grams) == [60])
    }
}

@Suite("GuideFormat")
@MainActor
struct GuideFormatTests {
    private let english = Locale(identifier: "en_US")

    @Test func aContainerReadsAsItsSizeCupsAndMl() {
        let plate = GuideContainer(id: "plate", name: "Plate", kind: "plate", cups: 2, ml: 473, inches: 10)
        let bowl = GuideContainer(id: "small_bowl", name: "Small bowl", kind: "bowl", cups: 0.88, ml: 207, inches: nil)
        #expect(GuideFormat.size(of: plate, locale: english) == "10 in · 2 cups · 473 ml")
        #expect(GuideFormat.size(of: bowl, locale: english) == "0.88 cups · 207 ml")
    }

    @Test func spoonsAndOilReadAsSent() {
        let little = GuideFatLevel(id: "little", name: "Little", tbspPerPlate: 0.33, looks: nil)
        let normal = GuideFatLevel(id: "normal", name: "Normal", tbspPerPlate: 1, looks: nil)
        #expect(GuideFormat.ml(14.8, locale: english) == "15 ml")
        #expect(GuideFormat.oil(little, locale: english) == "0.33 tbsp a plate")
        #expect(GuideFormat.oil(normal, locale: english) == "1 tbsp a plate")
    }

    @Test func weightsAreWholeGramsExceptUnderTen() {
        #expect(GuideFormat.grams(158, locale: english) == "158 g")
        #expect(GuideFormat.grams(259.9, locale: english) == "260 g")
        #expect(GuideFormat.grams(4.5, locale: english) == "4.5 g")
        #expect(GuideFormat.grams(7, locale: english) == "7 g")
    }

    @Test func aPhotoIsReadFromTheGuideImagesFolder() throws {
        let base = try #require(URL(string: "https://guide.example"))
        #expect(GuideImage.url(for: "rice_cooked-191g", base: base).absoluteString
            == "https://guide.example/guide-images/rice_cooked-191g.jpg")
    }
}

@Suite("PortionGuideStore")
@MainActor
struct PortionGuideStoreTests {
    private struct FakeService: PortionGuideService {
        var result: Result<Data, Error>
        func fetchGuideData() async throws -> Data { try result.get() }
    }

    private let savedURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("portion-guide-\(UUID().uuidString).json")

    private func store(fetching result: Result<Data, Error>, bundled: Data? = GuideFixture.payload()) -> PortionGuideStore {
        PortionGuideStore(service: FakeService(result: result), savedURL: savedURL, bundled: bundled)
    }

    @Test func aNewRevisionReplacesTheGuideAndIsSaved() async {
        let fetched = GuideFixture.payload(revision: "r2", foods: [GuideFixture.rice, GuideFixture.samosa])
        let store = store(fetching: .success(fetched))
        #expect(store.guide.revision == "r1")

        await store.refresh()
        #expect(store.guide.revision == "r2")
        #expect(store.guide.foods.count == 2)
        #expect((try? Data(contentsOf: savedURL)) == fetched)
    }

    @Test func theSavedCopyWinsOverTheBundledOne() throws {
        try GuideFixture.payload(revision: "saved").write(to: savedURL)
        #expect(store(fetching: .failure(URLError(.notConnectedToInternet))).guide.revision == "saved")
    }

    @Test func aFailedFetchKeepsTheGuide() async {
        let store = store(fetching: .failure(URLError(.notConnectedToInternet)))
        await store.refresh()
        #expect(store.guide.revision == "r1")
        #expect(!FileManager.default.fileExists(atPath: savedURL.path))
    }

    @Test func aPayloadThisBuildCannotShowKeepsTheGuide() async {
        let store = store(fetching: .success(GuideFixture.payload(version: 2, revision: "r9")))
        await store.refresh()
        #expect(store.guide.revision == "r1")
        #expect(!FileManager.default.fileExists(atPath: savedURL.path))
    }

    @Test func theSameRevisionIsNotSavedAgain() async {
        let store = store(fetching: .success(GuideFixture.payload()))
        await store.refresh()
        #expect(!FileManager.default.fileExists(atPath: savedURL.path))
    }

    @Test func withNothingToReadTheGuideIsEmpty() {
        #expect(store(fetching: .failure(URLError(.badServerResponse)), bundled: nil).guide == .empty)
    }
}
