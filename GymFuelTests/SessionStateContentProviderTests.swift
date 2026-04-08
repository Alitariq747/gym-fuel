import Testing
@testable import GymFuel

struct SessionStateContentProviderTests {
    private let provider = SessionStateContentProvider()

    @Test
    func scheduledSubstates_haveContentAndKeepTone() {
        assertContent(.training(.scheduled), .scheduled(.underFueled), .focused)
        assertContent(.training(.scheduled), .scheduled(.onTarget), .focused)
        assertContent(.training(.scheduled), .scheduled(.overFueled), .focused)
    }

    @Test
    func preWorkoutSubstates_haveContentAndKeepTone() {
        assertContent(.training(.preWorkout), .preWorkout(.needPreMeal), .assertive)
        assertContent(.training(.preWorkout), .preWorkout(.lowCarbPre), .assertive)
        assertContent(.training(.preWorkout), .preWorkout(.heavy), .assertive)
        assertContent(.training(.preWorkout), .preWorkout(.onTarget), .assertive)
    }

    @Test
    func inWorkoutSubstate_hasContentAndKeepsTone() {
        assertContent(.training(.inWorkout), .inWorkout(.hydratedAndFueled), .focused)
    }

    @Test
    func postWorkoutSubstates_haveContentAndKeepTone() {
        assertContent(.training(.postWorkout), .postWorkout(.needRecoveryMeal), .recovery)
        assertContent(.training(.postWorkout), .postWorkout(.lowProteinRecovery), .recovery)
        assertContent(.training(.postWorkout), .postWorkout(.lowCarbRecovery), .recovery)
        assertContent(.training(.postWorkout), .postWorkout(.recoveryOnTrack), .recovery)
    }

    @Test
    func supportSubstates_haveContentAndKeepTone() {
        assertContent(.training(.support), .support(.underFueled), .focused)
        assertContent(.training(.support), .support(.onTarget), .focused)
        assertContent(.training(.support), .support(.overFueled), .focused)
    }

    @Test
    func fallback_restDay_hasContent() {
        let content = provider.resolveContent(dayMode: .rest, substate: nil, tone: .calm)

        #expect(content.title.isEmpty == false)
        #expect(content.message.isEmpty == false)
        #expect(content.nextRecommendation.isEmpty == false)
        #expect(content.tone == .calm)
    }

    private func assertContent(
        _ dayMode: DayMode,
        _ substate: TrainingSubstate,
        _ tone: SessionTone
    ) {
        let content = provider.resolveContent(dayMode: dayMode, substate: substate, tone: tone)

        #expect(content.title.isEmpty == false)
        #expect(content.message.isEmpty == false)
        #expect(content.nextRecommendation.isEmpty == false)
        #expect(content.tone == tone)
    }
}
