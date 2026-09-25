import SwiftUI

/// One frame of a move. Angles are degrees; distances are canvas points, and a
/// negative `lift` is up.
struct MascotPose {
    var leftArm = 0.0
    var rightArm = 0.0
    var leftLeg = 0.0
    var rightLeg = 0.0
    /// On tiptoe: the body rises and the legs stretch, so the feet stay down.
    var reach = 0.0
    /// Moves the whole figure, feet included, so it can leave the ground.
    var lift = 0.0
    var tilt = 0.0
    var squash = 1.0
    var lookX = 0.0
    var lookY = 0.0
    var propLift = 0.0
    var propTurn = 0.0
}

/// Which drawings a move uses, beyond the plate, mouth and legs.
struct MascotCostume {
    var leftArm: String? = "MascotArmLeft"
    var rightArm: String? = "MascotArmRight"
    /// Held in front of the plate, arms included, and raised by `propLift`.
    var held: String?
    var eyes = "MascotEyes"
    /// Stands behind the figure.
    var ground: String?
    /// Floats beside the figure, bobs with `propLift` and swings with `propTurn`.
    var air: String?

    /// Closed eyes have nothing to blink.
    var blinks: Bool { eyes == "MascotEyes" }
}

extension PlateMascot.Move {
    /// Every loop starts and ends here, and it is all Reduce Motion shows.
    var rest: MascotPose {
        switch self {
        case .wave, .walk: MascotPose()
        case .wonder: MascotPose(lookX: 3, lookY: -3)
        case .stretch: MascotPose(rightArm: -8, reach: 14)
        case .weigh: MascotPose(lift: -8, lookY: 5)
        case .lookAhead: MascotPose(lookX: 6)
        case .write: MascotPose(lookX: -3, lookY: 5)
        case .phone: MascotPose(lookX: 4, lookY: 5)
        case .bell: MascotPose(lookX: 4, lookY: -5)
        case .hug: MascotPose()
        }
    }

    var costume: MascotCostume {
        switch self {
        case .wave: MascotCostume(rightArm: "MascotArmRightRaised")
        case .wonder: MascotCostume(air: "MascotQuestion")
        case .stretch: MascotCostume(rightArm: "MascotArmRightRaised", ground: "MascotRuler")
        case .weigh: MascotCostume(ground: "MascotScale")
        case .walk: MascotCostume()
        case .lookAhead: MascotCostume(ground: "MascotFlag")
        case .write:
            MascotCostume(leftArm: nil, rightArm: "MascotArmRightPencil", held: "MascotNotepadHold")
        case .phone: MascotCostume(rightArm: nil, held: "MascotPhoneHold")
        case .bell: MascotCostume(air: "MascotBell")
        case .hug:
            MascotCostume(leftArm: nil, rightArm: nil, held: "MascotHug", eyes: "MascotEyesHappy")
        }
    }
}

enum MascotKeyframes {
    @KeyframesBuilder<MascotPose>
    static func wave() -> some Keyframes<MascotPose> {
        KeyframeTrack(\.rightArm) {
            CubicKeyframe(-16, duration: 0.3)
            CubicKeyframe(10, duration: 0.35)
            CubicKeyframe(-16, duration: 0.35)
            CubicKeyframe(10, duration: 0.35)
            CubicKeyframe(0, duration: 0.35)
            LinearKeyframe(0, duration: 3.1)
        }
    }

    @KeyframesBuilder<MascotPose>
    static func wonder() -> some Keyframes<MascotPose> {
        KeyframeTrack(\.tilt) {
            CubicKeyframe(-5, duration: 0.8)
            LinearKeyframe(-5, duration: 0.6)
            CubicKeyframe(3, duration: 0.9)
            CubicKeyframe(0, duration: 0.7)
        }
        KeyframeTrack(\.propLift) {
            CubicKeyframe(-6, duration: 0.75)
            CubicKeyframe(0, duration: 0.75)
            CubicKeyframe(-6, duration: 0.75)
            CubicKeyframe(0, duration: 0.75)
        }
    }

    @KeyframesBuilder<MascotPose>
    static func stretch() -> some Keyframes<MascotPose> {
        KeyframeTrack(\.reach) {
            LinearKeyframe(14, duration: 0.9)
            CubicKeyframe(2, duration: 0.4)
            LinearKeyframe(2, duration: 1)
            CubicKeyframe(14, duration: 0.7)
        }
        KeyframeTrack(\.rightArm) {
            LinearKeyframe(-8, duration: 0.9)
            CubicKeyframe(0, duration: 0.4)
            LinearKeyframe(0, duration: 1)
            CubicKeyframe(-8, duration: 0.7)
        }
    }

    @KeyframesBuilder<MascotPose>
    static func weigh() -> some Keyframes<MascotPose> {
        KeyframeTrack(\.lift) {
            CubicKeyframe(-28, duration: 0.35)
            CubicKeyframe(-7, duration: 0.25)
            CubicKeyframe(-8, duration: 0.2)
            LinearKeyframe(-8, duration: 2.2)
        }
        KeyframeTrack(\.squash) {
            LinearKeyframe(1, duration: 0.35)
            CubicKeyframe(0.94, duration: 0.25)
            CubicKeyframe(1, duration: 0.2)
            LinearKeyframe(1, duration: 2.2)
        }
    }

    @KeyframesBuilder<MascotPose>
    static func walk() -> some Keyframes<MascotPose> {
        step(\.leftLeg, by: 16)
        step(\.rightLeg, by: -16)
        step(\.leftArm, by: -16)
        step(\.rightArm, by: 16)
        KeyframeTrack(\.lift) {
            CubicKeyframe(-4, duration: 0.2)
            CubicKeyframe(0, duration: 0.2)
            CubicKeyframe(-4, duration: 0.2)
            CubicKeyframe(0, duration: 0.2)
        }
    }

    @KeyframesBuilder<MascotPose>
    static func lookAhead() -> some Keyframes<MascotPose> {
        KeyframeTrack(\.lift) {
            CubicKeyframe(-8, duration: 0.18)
            CubicKeyframe(0, duration: 0.18)
            CubicKeyframe(-8, duration: 0.18)
            CubicKeyframe(0, duration: 0.18)
            LinearKeyframe(0, duration: 1.68)
        }
    }

    @KeyframesBuilder<MascotPose>
    static func write() -> some Keyframes<MascotPose> {
        KeyframeTrack(\.rightArm) {
            CubicKeyframe(-4, duration: 0.12)
            CubicKeyframe(3, duration: 0.12)
            CubicKeyframe(-4, duration: 0.12)
            CubicKeyframe(3, duration: 0.12)
            CubicKeyframe(-4, duration: 0.12)
            CubicKeyframe(0, duration: 0.12)
            LinearKeyframe(0, duration: 0.48)
        }
        KeyframeTrack(\.tilt) {
            CubicKeyframe(2, duration: 0.6)
            CubicKeyframe(0, duration: 0.6)
        }
    }

    @KeyframesBuilder<MascotPose>
    static func phone() -> some Keyframes<MascotPose> {
        rise(\.propLift, to: -5)
        rise(\.tilt, to: 3)
    }

    @KeyframesBuilder<MascotPose>
    static func bell() -> some Keyframes<MascotPose> {
        KeyframeTrack(\.propTurn) {
            CubicKeyframe(14, duration: 0.15)
            CubicKeyframe(-12, duration: 0.2)
            CubicKeyframe(10, duration: 0.2)
            CubicKeyframe(-8, duration: 0.2)
            CubicKeyframe(4, duration: 0.2)
            CubicKeyframe(0, duration: 0.2)
            LinearKeyframe(0, duration: 0.85)
        }
        KeyframeTrack(\.lift) {
            CubicKeyframe(-6, duration: 0.15)
            CubicKeyframe(0, duration: 0.2)
            LinearKeyframe(0, duration: 1.65)
        }
    }

    @KeyframesBuilder<MascotPose>
    static func hug() -> some Keyframes<MascotPose> {
        KeyframeTrack(\.tilt) {
            CubicKeyframe(-4, duration: 0.8)
            CubicKeyframe(4, duration: 1.6)
            CubicKeyframe(0, duration: 0.8)
        }
    }

    /// Up to `target`, a pause, back to rest, a pause: the phone's slow lift.
    private static func rise(
        _ value: WritableKeyPath<MascotPose, Double>,
        to target: Double
    ) -> some Keyframes<MascotPose> {
        KeyframeTrack(value) {
            CubicKeyframe(target, duration: 0.6)
            LinearKeyframe(target, duration: 1.2)
            CubicKeyframe(0, duration: 0.6)
            LinearKeyframe(0, duration: 0.6)
        }
    }

    /// Out one way, across to the other, back to rest: one stride of the walk.
    private static func step(
        _ angle: WritableKeyPath<MascotPose, Double>,
        by amount: Double
    ) -> some Keyframes<MascotPose> {
        KeyframeTrack(angle) {
            CubicKeyframe(amount, duration: 0.2)
            CubicKeyframe(-amount, duration: 0.4)
            CubicKeyframe(0, duration: 0.2)
        }
    }
}
