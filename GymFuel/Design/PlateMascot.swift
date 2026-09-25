import SwiftUI

/// The plate mascot. Every piece is drawn on the same 300 × 300 canvas, so the
/// pieces line up by stacking alone, and joints and distances are canvas points.
struct PlateMascot: View {
    enum Move: CaseIterable {
        case wave, wonder, stretch, weigh, walk, lookAhead, write, phone, bell, hug
    }

    let move: Move

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            Group {
                if reduceMotion {
                    figure(Idle(), move.rest)
                } else {
                    KeyframeAnimator(initialValue: Idle(), repeating: true) { idle in
                        moving(idle)
                    } keyframes: { _ in
                        KeyframeTrack(\.breath) {
                            CubicKeyframe(1.015, duration: 1.2)
                            CubicKeyframe(1, duration: 1.2)
                            CubicKeyframe(1.015, duration: 1.2)
                            CubicKeyframe(1, duration: 1.2)
                        }
                        KeyframeTrack(\.eyeOpen) {
                            LinearKeyframe(1, duration: 3.9)
                            LinearKeyframe(0.1, duration: 0.08)
                            LinearKeyframe(1, duration: 0.1)
                            LinearKeyframe(1, duration: 0.72)
                        }
                    }
                }
            }
            .frame(width: Rig.canvas, height: Rig.canvas)
            .scaleEffect(min(proxy.size.width, proxy.size.height) / Rig.canvas)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func moving(_ idle: Idle) -> some View {
        switch move {
        case .wave: animated(idle, MascotKeyframes.wave)
        case .wonder: animated(idle, MascotKeyframes.wonder)
        case .stretch: animated(idle, MascotKeyframes.stretch)
        case .weigh: animated(idle, MascotKeyframes.weigh)
        case .walk: animated(idle, MascotKeyframes.walk)
        case .lookAhead: animated(idle, MascotKeyframes.lookAhead)
        case .write: animated(idle, MascotKeyframes.write)
        case .phone: animated(idle, MascotKeyframes.phone)
        case .bell: animated(idle, MascotKeyframes.bell)
        case .hug: animated(idle, MascotKeyframes.hug)
        }
    }

    private func animated<K: Keyframes>(
        _ idle: Idle,
        _ keyframes: @escaping () -> K
    ) -> some View where K.Value == MascotPose {
        KeyframeAnimator(initialValue: move.rest, repeating: true) { pose in
            figure(idle, pose)
        } keyframes: { _ in
            keyframes()
        }
    }

    private func figure(_ idle: Idle, _ pose: MascotPose) -> some View {
        let costume = move.costume
        return ZStack {
            piece("MascotShadow")
            if let ground = costume.ground { piece(ground) }
            ZStack {
                ZStack {
                    piece("MascotLegLeft")
                        .rotationEffect(.degrees(pose.leftLeg), anchor: Rig.leftHip)
                    piece("MascotLegRight")
                        .rotationEffect(.degrees(pose.rightLeg), anchor: Rig.rightHip)
                }
                .scaleEffect(x: 1, y: 1 + pose.reach / Rig.legLength, anchor: Rig.feet)
                ZStack {
                    piece("MascotPlate")
                    piece(costume.eyes)
                        .scaleEffect(x: 1, y: costume.blinks ? idle.eyeOpen : 1, anchor: Rig.eyeLine)
                        .offset(x: pose.lookX, y: pose.lookY)
                    piece("MascotMouth")
                    if let held = costume.held {
                        piece(held).offset(y: pose.propLift)
                    }
                    if let leftArm = costume.leftArm {
                        piece(leftArm)
                            .rotationEffect(.degrees(pose.leftArm), anchor: Rig.leftShoulder)
                    }
                    if let rightArm = costume.rightArm {
                        piece(rightArm)
                            .rotationEffect(.degrees(pose.rightArm), anchor: Rig.rightShoulder)
                    }
                }
                .offset(y: -pose.reach)
            }
            .scaleEffect(x: idle.breath, y: idle.breath * pose.squash, anchor: Rig.feet)
            .rotationEffect(.degrees(pose.tilt), anchor: Rig.feet)
            .offset(y: pose.lift)
            if let air = costume.air {
                piece(air)
                    .rotationEffect(.degrees(pose.propTurn), anchor: Rig.bellHook)
                    .offset(y: pose.propLift)
            }
        }
    }

    /// Drawings carry their own colours, with dark versions in the asset catalogue.
    /// Don't tint them: an arm across the plate must stay dark in dark mode,
    /// because the plate stays light.
    private func piece(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
    }
}

/// Blinking and breathing, which run under every move.
private struct Idle {
    var breath = 1.0
    var eyeOpen = 1.0
}

/// Joints, in the drawings' own 300 × 300 coordinates.
private enum Rig {
    static let canvas: CGFloat = 300
    static let leftShoulder = point(67, 155)
    static let rightShoulder = point(233, 155)
    static let leftHip = point(133, 200)
    static let rightHip = point(167, 200)
    static let eyeLine = point(150, 117)
    static let feet = point(150, 270)
    static let bellHook = point(262, 22)
    static let legLength: CGFloat = 70

    private static func point(_ x: CGFloat, _ y: CGFloat) -> UnitPoint {
        UnitPoint(x: x / canvas, y: y / canvas)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
        ForEach(PlateMascot.Move.allCases, id: \.self) { move in
            PlateMascot(move: move)
                .frame(height: 110)
        }
    }
    .padding()
    .circaPaper()
    .preferredColorScheme(.dark)
}
