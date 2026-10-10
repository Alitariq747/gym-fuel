//
//  WidgetGuideCopyTests.swift
//  GymFuelTests
//

import Testing

@testable import LiftEats

@Suite("Widget guide copy")
struct WidgetGuideCopyTests {

    @Test("iOS 18 and later: Edit, then Add Widget")
    func editButton() {
        let steps = WidgetGuideCopy.steps(for: .homeScreen, hasEditButton: true)
        #expect(steps[1] == "Tap **Edit**, then **Add Widget**.")
    }

    @Test("iOS 17: the plus button")
    func plusButton() {
        let steps = WidgetGuideCopy.steps(for: .homeScreen, hasEditButton: false)
        #expect(steps[1] == "Tap **+** in the top corner.")
    }

    @Test("Home Screen: four steps either way, and only the second differs")
    func onlyTheSecondHomeStepDiffers() {
        let withEdit = WidgetGuideCopy.steps(for: .homeScreen, hasEditButton: true)
        let withPlus = WidgetGuideCopy.steps(for: .homeScreen, hasEditButton: false)
        #expect(withEdit.count == 4)
        #expect(withPlus.count == 4)
        for index in [0, 2, 3] {
            #expect(withEdit[index] == withPlus[index])
        }
    }

    @Test("Lock Screen: four steps, starting at Customize")
    func lockScreenSteps() {
        let steps = WidgetGuideCopy.steps(for: .lockScreen, hasEditButton: true)
        #expect(steps.count == 4)
        #expect(steps[0].contains("**Customize**"))
    }

    @Test("Lock Screen: the same on every iOS")
    func lockScreenIgnoresTheEditButton() {
        #expect(
            WidgetGuideCopy.steps(for: .lockScreen, hasEditButton: true)
                == WidgetGuideCopy.steps(for: .lockScreen, hasEditButton: false)
        )
    }

    @Test("Both places name the app")
    func bothPlacesNameTheApp() {
        for place in WidgetGuideCopy.Place.allCases {
            let steps = WidgetGuideCopy.steps(for: place, hasEditButton: true)
            #expect(steps.contains { $0.contains("**Circa**") }, "\(place)")
        }
    }
}
