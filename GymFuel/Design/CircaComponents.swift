//
//  CircaComponents.swift
//  GymFuel
//
//  The shapes. `CircaTheme.swift` holds the values; this file holds the things
//  that repeat and the things that carry a rule. Both are specified in
//  `design.md` — if a shape here and a screen there disagree, the doc wins.
//
//  Three rules live in here rather than on any screen, deliberately:
//
//  1. **The certainty rule** (`CircaEstimate`, design.md rule 1). Three states,
//     one of which has no number at all. The whole promise is that nothing
//     jumps when an estimate lands, and that only survives if one piece of code
//     owns it.
//  2. **AX3 layout** (design.md rule 8). The row goes vertical, the bars stack,
//     the dock drops its labels. Every component that has an accessibility-size
//     layout switches itself. No screen reads `dynamicTypeSize` to lay out a
//     component from this file.
//  3. **The dark inversion** (design.md rule 7). `circaInk` and `circaPaperTop`
//     are both adaptive, so a primary button is dark-on-paper in light and
//     light-on-dark in dark with no branch. Do not add one.
//
//  Adding to this file: extract only what genuinely repeats, or what carries a
//  rule. Anything that appears on one screen stays inline on that screen.
//

import SwiftUI
import WidgetKit

// MARK: - Metrics local to the kit

/// Measurements read off the canvas artboards that are specific to one shape,
/// and so do not belong in `CircaTheme`'s shared metrics.
private enum Kit {
    /// Gap between a number and its certainty rule. Applied in all three
    /// states, so a settled row and an estimated row share a baseline.
    static let certaintyGap: CGFloat = 3
    /// Width of the rule when it stands alone — the pending state.
    static let pendingRuleWidth: CGFloat = 38

    static let entryRowGap: CGFloat = 13
    static let settleBeat: Double = 0.12
    static let macroWell: CGFloat = 32
    static let macroWellLarge: CGFloat = 40
    static let symbolWell: CGFloat = 40
    static let inlineGlyph: CGFloat = 12

    static let barHeight: CGFloat = 3
    static let barHeightAX: CGFloat = 4
    static let barRadius: CGFloat = 2
    static let recolouredTrackOpacity: Double = 0.3
    static let barStagger: Double = 0.06

    static let dockItemHeight: CGFloat = 48
    static let dockItemHeightAX: CGFloat = 56
}

// MARK: - Paper

extension View {
    /// The body background. Every screen sits on paper, and the part screens
    /// get wrong is the safe area, not the gradient.
    func circaPaper() -> some View {
        background(LinearGradient.circaPaper.ignoresSafeArea())
    }

    /// The soft shadow under a surface meant to be touched — the dock, the
    /// onboarding meal field.
    func circaLift() -> some View {
        shadow(color: Color.circaInk.opacity(0.05), radius: 3, y: 1)
            .shadow(color: Color.circaInk.opacity(0.07), radius: 26, y: 10)
    }
}

// MARK: - Hairline

/// A divider. Two weights, and which one is correct depends only on whether you
/// are inside a card — which is exactly the thing thirty call sites get wrong.
struct CircaHairline: View {
    enum Weight {
        /// Between blocks on a screen.
        case section
        /// Inside a card. Lighter.
        case inCard
    }

    var weight: Weight = .section

    var body: some View {
        Rectangle()
            .fill(weight == .section ? Color.circaRule : Color.circaRuleSoft)
            .frame(height: Circa.Rule.hairline)
    }
}

// MARK: - Card

/// The four grounds a block can sit on. Chosen by meaning, not by colour.
enum CircaSurface {
    /// Raised — the day summary, the meal analysis card.
    case raised
    /// Recessed — the check-in prompt, an inline note.
    case sunken
    /// Ink ground — the loudest thing on a screen.
    ///
    /// Inverts with the theme, like the primary button: `circaInk` is near-black
    /// on paper and near-white in dark, and the content follows it.
    case inverted
    /// Failure. Warm brick, never a system red — design.md rule 5.
    case danger

    fileprivate var ground: Color {
        switch self {
        case .raised: return .circaCard
        case .sunken: return .circaSunken
        case .inverted: return .circaInk
        case .danger: return .circaDangerGround
        }
    }

    fileprivate var border: Color? {
        switch self {
        case .raised: return .circaCardBorder
        case .sunken: return nil
        case .inverted: return nil
        case .danger: return .circaDangerBorder
        }
    }

    /// The ink a label takes when it sits on this ground.
    var foreground: Color {
        self == .inverted ? .circaPaperTop : .circaInk
    }
}

struct CircaCard<Content: View>: View {
    var surface: CircaSurface = .raised
    var radius: CGFloat = Circa.Radius.card
    var inset: EdgeInsets
    @ViewBuilder var content: () -> Content

    init(
        _ surface: CircaSurface = .raised,
        radius: CGFloat = Circa.Radius.card,
        inset: EdgeInsets = EdgeInsets(
            top: Circa.Space.cardInset,
            leading: Circa.Space.cardInset,
            bottom: Circa.Space.cardInset,
            trailing: Circa.Space.cardInset
        ),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.surface = surface
        self.radius = radius
        self.inset = inset
        self.content = content
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    var body: some View {
        content()
            .foregroundStyle(surface.foreground)
            .padding(inset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(surface.ground, in: shape)
            .overlay {
                if let border = surface.border {
                    shape.strokeBorder(border, lineWidth: Circa.Rule.hairline)
                }
            }
    }
}

// MARK: - Section label

/// Mono, uppercase, tracked. These replace bold sans headers everywhere —
/// design.md, "Type — two faces, two jobs".
struct CircaSectionLabel: View {
    let text: String
    var tint: Color = .circaInk3

    init(_ text: String, tint: Color = .circaInk3) {
        self.text = text
        self.tint = tint
    }

    /// The tint to use on a `.inverted` card, where `circaInk3` would vanish.
    static func onInverted(_ text: String) -> CircaSectionLabel {
        CircaSectionLabel(text, tint: Color.circaPaperTop.opacity(0.66))
    }

    var body: some View {
        Text(text.uppercased())
            .font(.circaMono)
            .tracking(Circa.sectionLabelTracking)
            .foregroundStyle(tint)
            .accessibilityLabel(text)
    }
}

/// A section label with one link on its right, like "Sources ›". The link
/// drops under the label at AX sizes.
struct CircaSectionHeader: View {
    let title: String
    let link: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let isStacked = typeSize.isAccessibilitySize
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6))

        layout {
            CircaSectionLabel(title)
            if !isStacked { Spacer(minLength: Circa.Space.rowGap) }
            Button(action: action) {
                HStack(spacing: 4) {
                    Text(link)
                    Image(systemName: "chevron.forward")
                        .font(.circaCaption.weight(.semibold))
                }
                .font(.circaCaption.weight(.medium))
            }
            .buttonStyle(.circa(.link))
            // Keeps the 44 pt tap area without making the header taller. At AX
            // sizes the text is taller than 44 pt already.
            .padding(.vertical, isStacked ? 0 : -14)
            .padding(isStacked ? .leading : .trailing, -10)
        }
    }
}

// MARK: - The certainty rule

/// How sure the number above the rule is. design.md rule 1, and the mark that
/// makes the name mean something.
///
/// The third case is the reason this is a type and not a `Bool`: the same rule
/// that means *estimated* under a settled number means *not yet known* when it
/// stands alone, so nothing jumps when the estimate lands. No spinner, no zero,
/// no placeholder digits.
enum CircaCertainty {
    /// Estimated by the AI. Dotted rule under the number.
    case estimated
    /// A saved meal, or a number the user corrected. No rule.
    case known
    /// Still analysing. The rule alone, with nothing above it.
    case pending
}

/// The dotted rule itself. 1.5pt round dots, `circaDotted`.
private struct CertaintyRule: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let y = Circa.Rule.certaintyWidth / 2
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: geo.size.width, y: y))
            }
            .stroke(
                Color.circaDotted,
                style: StrokeStyle(
                    lineWidth: Circa.Rule.certaintyWidth,
                    lineCap: .round,
                    // A near-zero dash with a round cap renders a dot, not a
                    // dash — this is what matches CSS `dotted` on the canvas.
                    dash: [0.01, 3]
                )
            )
        }
        .frame(height: Circa.Rule.certaintyWidth)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Applies the certainty rule to a number you have already laid out — the
    /// 44pt total on the entry screen, a per-item row.
    ///
    /// The bottom gap is applied in **all three** states, so a settled row and
    /// an estimated row share a baseline in the same list.
    ///
    /// For a number that may not exist yet, use `CircaEstimate` instead: this
    /// modifier cannot render the pending state, because there is nothing to
    /// modify.
    func certaintyRule(_ certainty: CircaCertainty) -> some View {
        padding(.bottom, Kit.certaintyGap)
            .overlay(alignment: .bottom) {
                if certainty != .known {
                    CertaintyRule()
                }
            }
    }
}

/// A number that may or may not have arrived yet.
///
/// Pass `nil` and the pending rule is drawn alone, reserving the same line
/// height the number will take — so when the estimate lands, only the number
/// changes. If a row's height or a title's baseline moves between `.pending`
/// and `.estimated`, this is the thing that is wrong.
struct CircaEstimate: View {
    let value: String?
    let certainty: CircaCertainty
    var font: Font = .circaMonoValue

    @ScaledMetric(relativeTo: .callout) private var pendingWidth = Kit.pendingRuleWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ value: String?, certainty: CircaCertainty, font: Font = .circaMonoValue) {
        self.value = value
        // A missing number is pending whatever the caller said, and a present
        // number is never pending. Keeps the two arguments from disagreeing.
        self.certainty = value == nil ? .pending : (certainty == .pending ? .estimated : certainty)
        self.font = font
    }

    var body: some View {
        Group {
            if let value {
                Text(value)
                    .transition(reduceMotion ? .opacity : AnyTransition(.blurReplace))
            } else {
                // Reserves the number's line height without drawing anything.
                Text(verbatim: "0")
                    .opacity(0)
                    .frame(width: pendingWidth)
            }
        }
        .font(font)
        .monospacedDigit()
        .certaintyRule(certainty)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard let value else { return "Still estimating" }
        switch certainty {
        case .estimated: return "\(value), estimated"
        case .known, .pending: return value
        }
    }
}

// MARK: - Buttons

/// Which of the four tiers a button is. Colour carries no meaning here —
/// design.md rule 5 — so the tier is the whole hierarchy.
enum CircaButtonTier: Equatable {
    /// Filled. One per screen.
    case primary
    /// Raised, bordered. The companion to a primary.
    case secondary
    /// Bordered only, no fill.
    case outline
    /// No chrome at all.
    case text(CircaTextTone)

    /// A text button that leads somewhere — "See the week".
    static let link = CircaButtonTier.text(.accent)
    /// A text button that declines — "Not now".
    static let quiet = CircaButtonTier.text(.quiet)
}

enum CircaTextTone: Equatable {
    case accent
    case quiet
}

struct CircaButtonStyle: ButtonStyle {
    let tier: CircaButtonTier
    var height: CGFloat = 46

    func makeBody(configuration: Configuration) -> some View {
        content(configuration)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    @ViewBuilder
    private func content(_ configuration: Configuration) -> some View {
        switch tier {
        case .text(let tone):
            configuration.label
                .font(.system(.callout).weight(.medium))
                .foregroundStyle(tone == .accent ? Color.circaAccent : Color.circaInk3)
                .padding(.horizontal, 10)
                // No visible box, but the 44pt floor still holds — design.md
                // "Hit target: 44pt minimum, no exceptions".
                .frame(minHeight: Circa.minHitTarget)
                .contentShape(Rectangle())

        case .primary, .secondary, .outline:
            configuration.label
                .font(.system(.callout).weight(tier == .primary ? .semibold : .medium))
                .foregroundStyle(foreground)
                .padding(.horizontal, 18)
                .frame(minHeight: height)
                .background(fill, in: shape)
                .overlay {
                    if let border {
                        shape.strokeBorder(border, lineWidth: Circa.Rule.hairline)
                    }
                }
                .contentShape(shape)
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Circa.Radius.button, style: .continuous)
    }

    /// `circaInk` and `circaPaperTop` are both adaptive, so this single pair is
    /// a dark button with a light label on paper, and a light button with a
    /// dark label in dark. That is design.md rule 7, and it needs no branch.
    private var foreground: Color {
        tier == .primary ? .circaPaperTop : .circaInk
    }

    private var fill: Color {
        switch tier {
        case .primary: return .circaInk
        case .secondary: return .circaCard
        default: return .clear
        }
    }

    private var border: Color? {
        switch tier {
        case .secondary, .outline: return .circaRule
        default: return nil
        }
    }
}

extension ButtonStyle where Self == CircaButtonStyle {
    /// `Button("Looks right") { }.buttonStyle(.circa(.primary))`
    ///
    /// `height` is the filled tiers' minimum; the paywall's full-width primary
    /// is 54. Text tiers ignore it and hold the 44pt floor.
    static func circa(_ tier: CircaButtonTier, height: CGFloat = 46) -> CircaButtonStyle {
        CircaButtonStyle(tier: tier, height: height)
    }
}

// MARK: - Macro bars

struct CircaMacroValue: Equatable {
    let consumed: Int
    let target: Int

    init(consumed: Int, target: Int) {
        self.consumed = consumed
        self.target = target
    }

    fileprivate var fraction: Double {
        guard target > 0 else { return 0 }
        return min(max(Double(consumed) / Double(target), 0), 1)
    }

    /// What VoiceOver says for one macro, wherever its bar is drawn.
    func spoken(_ name: String) -> String {
        "\(name), \(consumed) of \(target) grams"
    }
}

/// One macro's bar: ink filling its track toward the target, never past it.
struct CircaMacroBar: View {
    let value: CircaMacroValue

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Tinted and clear widgets keep only opacity: a solid track would match the fill.
                RoundedRectangle(cornerRadius: Kit.barRadius, style: .continuous)
                    .fill(renderingMode == .fullColor ? Color.circaBarTrack : Color.circaInk.opacity(Kit.recolouredTrackOpacity))
                RoundedRectangle(cornerRadius: Kit.barRadius, style: .continuous)
                    .fill(Color.circaInk)
                    .frame(width: geo.size.width * value.fraction)
            }
        }
        .frame(height: typeSize.isAccessibilitySize ? Kit.barHeightAX : Kit.barHeight)
    }
}

/// The three macro bars under a day total.
///
/// At accessibility sizes the three columns stack rather than fighting for
/// width — design.md rule 8. The screen never has to know that.
struct CircaMacroBars: View {
    let protein: CircaMacroValue
    let carbs: CircaMacroValue
    let fat: CircaMacroValue
    /// How a change settles, one bar after another. Nil snaps.
    var animation: Animation? = nil

    @Environment(\.dynamicTypeSize) private var typeSize

    private var isStacked: Bool { typeSize.isAccessibilitySize }

    private var bars: [(glyph: CircaMacroGlyph.Macro, name: String, value: CircaMacroValue)] {
        [(.protein, "Protein", protein), (.carbs, "Carbs", carbs), (.fat, "Fat", fat)]
    }

    var body: some View {
        if isStacked {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(bars.indices, id: \.self) { bar(at: $0) }
            }
        } else {
            HStack(alignment: .top, spacing: 14) {
                ForEach(bars.indices, id: \.self) { bar(at: $0) }
            }
        }
    }

    private func bar(at index: Int) -> some View {
        let (glyph, name, value) = bars[index]

        return VStack(alignment: .leading, spacing: isStacked ? 6 : 5) {
            CircaMacroBar(value: value)

            // Bare, without the well: three columns leave no room for one.
            HStack(spacing: 4) {
                CircaInlineGlyph(glyph)
                Text("\(value.consumed) / \(value.target)")
                    .font(.circaMono)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(value.consumed)))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Color.circaInk3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(animation?.delay(Double(index) * Kit.barStagger), value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.spoken(name))
    }
}

/// A target's mark in a round well — `design.md` rule 10's exception.
struct CircaMacroGlyph: View {
    enum Macro: String {
        case calories = "MacroCalories"
        case protein = "MacroProtein"
        case carbs = "MacroCarbs"
        case fat = "MacroFat"
    }

    enum Size {
        case regular
        /// Beside a meal's calorie total.
        case large
    }

    let macro: Macro

    @ScaledMetric private var size: CGFloat

    init(_ macro: Macro, size: Size = .regular) {
        self.macro = macro
        _size = ScaledMetric(
            wrappedValue: size == .large ? Kit.macroWellLarge : Kit.macroWell,
            relativeTo: .callout
        )
    }

    var body: some View {
        Circle()
            .fill(Color.circaWell)
            .overlay { Circle().strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline) }
            .overlay {
                Image(macro.rawValue)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.circaInk2)
                    .padding(size * 0.2)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// An SF Symbol in a round well. Emphasised, the well fills with ink.
struct CircaSymbolWell: View {
    let symbol: String
    var emphasised = false

    @ScaledMetric(relativeTo: .callout) private var size = Kit.symbolWell

    var body: some View {
        Image(systemName: symbol)
            .font(.circaRow)
            .foregroundStyle(emphasised ? Color.circaPaperTop : Color.circaInk2)
            .frame(width: size, height: size)
            .background(emphasised ? Color.circaInk : Color.circaWell, in: Circle())
            .overlay {
                Circle().strokeBorder(emphasised ? Color.circaInk : Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
            }
            .accessibilityHidden(true)
    }
}

/// A target's mark with no well, sized to sit beside a `circaMono` figure. It
/// takes the figure's ink.
struct CircaInlineGlyph: View {
    let macro: CircaMacroGlyph.Macro

    @ScaledMetric(relativeTo: .caption2) private var size = Kit.inlineGlyph

    init(_ macro: CircaMacroGlyph.Macro) {
        self.macro = macro
    }

    var body: some View {
        Image(macro.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// A target, its whole number and unit, and its glyph when it has one. Goes
/// vertical at AX sizes (`design.md` rule 8); the glyph stays beside both.
struct CircaTargetRow: View {
    let title: String
    let value: Double
    let suffix: String
    var font: Font = .circaMonoValue
    var glyph: CircaMacroGlyph.Macro?

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let isStacked = typeSize.isAccessibilitySize
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6))

        HStack(spacing: 12) {
            if let glyph { CircaMacroGlyph(glyph) }
            layout {
                Text(title)
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk)
                if !isStacked { Spacer(minLength: Circa.Space.rowGap) }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value.formatted(.number.precision(.fractionLength(0))))
                        .font(font)
                        .monospacedDigit()
                        .foregroundStyle(Color.circaInk)
                    Text(suffix)
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Progress rail

/// The sweep under a pending row. It says *working* where a percentage would
/// claim progress nobody is measuring, and it lives beside the certainty rule
/// because the two say the same thing: not yet known.
struct CircaProgressRail: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSweeping = false

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let sweepWidth = max(width * 0.34, 44)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.circaBarTrack)

                Capsule()
                    .fill(Color.circaAccent)
                    .frame(width: reduceMotion ? width * 0.42 : sweepWidth)
                    .offset(x: reduceMotion ? 0 : (isSweeping ? width : -sweepWidth))
            }
            .clipShape(Capsule())
        }
        .frame(height: Kit.barHeight)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            isSweeping = false
            withAnimation(.easeInOut(duration: 1.45).repeatForever(autoreverses: false)) {
                isSweeping = true
            }
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled { isSweeping = false }
        }
    }
}

/// The sweep across a photo that is being read. Never paired with a percentage.
struct ImageAnalysisScannerOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isScanning = false

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let scannerWidth = max(width * 0.28, 18)

            ZStack(alignment: .leading) {
                Color.clear

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.26),
                                Color.white.opacity(0.18),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: scannerWidth)
                    .offset(x: reduceMotion ? width * 0.36 : (isScanning ? width : -scannerWidth))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            isScanning = false
            withAnimation(.easeInOut(duration: 1.55).repeatForever(autoreverses: false)) {
                isScanning = true
            }
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled { isScanning = false }
        }
    }
}

// MARK: - Entry row

/// What sits at the head of a journal entry.
enum CircaEntryLeading {
    /// An SF Symbol in a bordered well — a text entry.
    case glyph(String)
    /// A photo, or its placeholder well when the image has not loaded.
    case photo(Image?)
    /// A photo whose loading the caller owns — the timeline fetches from cache,
    /// then from storage, so there is no `Image` to hand over up front. The kit
    /// still owns the well, the radius and the AX3 drop.
    case photoContent(AnyView)
    /// Nothing. Also what the row falls back to at accessibility sizes.
    case none
}

/// One entry in the day's journal — the product's unit.
///
/// Takes plain values rather than a `LogEntry` on purpose: the kit must not
/// know the model, or Step 3's deletions and Step 6's schema change reach in
/// here and every screen re-solves the row again.
///
/// At accessibility sizes the row goes vertical and the number drops below the
/// title — design.md rule 8. Right-aligned mono numerals beside left-aligned
/// wrapping text is the classic Dynamic Type break, and this is where it is
/// solved, once.
struct CircaEntryRow: View {
    let title: String
    let calories: String?
    var certainty: CircaCertainty = .estimated
    /// Mono metadata — `"08:20 · 9P 48C 21F"`.
    let meta: String
    /// The ochre line — `"3 assumptions · 2 tbsp oil…"`. Optional.
    var assumption: String? = nil
    var leading: CircaEntryLeading = .none
    /// The pending state — design.md rule 1's third row. The number has not
    /// arrived, so `meta` carries the status in ochre, the rail sweeps under it,
    /// and the assumption line waits. It is a mode of this row rather than a row
    /// of its own, because two components cannot promise the number lands in the
    /// place the rule is already holding.
    var isAnalysing: Bool = false

    @Environment(\.dynamicTypeSize) private var typeSize

    private var isVertical: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        Group {
            if isVertical { verticalLayout } else { horizontalLayout }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.vertical, isVertical ? 12 : 9)
        // One element per entry — the Foundations artboard commits to this.
        .accessibilityElement(children: .combine)
    }

    // MARK: Standard

    private var horizontalLayout: some View {
        HStack(alignment: .top, spacing: Kit.entryRowGap) {
            leadingWell

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 14) {
                    Text(title)
                        .font(.circaEntryTitle)
                        .foregroundStyle(titleInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    CircaEstimate(calories, certainty: certainty)
                        .layoutPriority(1)
                }

                Group {
                    if isAnalysing {
                        VStack(alignment: .leading, spacing: 5) {
                            metaLine
                            CircaProgressRail()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 3) {
                            metaLine
                            if let assumption {
                                Text(assumption)
                                    .font(.circaMono)
                                    .foregroundStyle(Color.circaAccent)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                // The same band under the title in both states, so the row keeps
                // its height when the estimate lands — design.md rule 1.
                .frame(minHeight: 40, alignment: .center)
                .transaction(value: isAnalysing) { $0.animation = $0.animation?.delay(Kit.settleBeat) }
            }
        }
    }

    // MARK: AX3

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.circaEntryTitle)
                .foregroundStyle(titleInk)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                CircaEstimate(calories, certainty: certainty)
                // Nothing to label while the rule stands alone.
                if calories != nil {
                    Text("kcal")
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                }
            }

            metaLine

            if isAnalysing {
                CircaProgressRail()
            }

            if let assumption, !isAnalysing {
                HStack(spacing: 6) {
                    Text(assumption)
                        .font(.circaMono)
                        .foregroundStyle(Color.circaAccent)
                        .fixedSize(horizontal: false, vertical: true)
                    // `.forward`, not `.right` — design.md rule 9, so Arabic
                    // mirrors without a second layout.
                    Image(systemName: "chevron.forward")
                        .font(.circaMono)
                        .foregroundStyle(Color.circaAccent)
                }
                .frame(minHeight: Circa.minHitTarget, alignment: .leading)
            }
        }
    }

    // MARK: Parts

    private var titleInk: Color {
        isAnalysing ? .circaInk2 : .circaInk
    }

    private var metaLine: some View {
        Text(meta)
            .font(.circaMono)
            .monospacedDigit()
            .foregroundStyle(isAnalysing ? Color.circaAccent : Color.circaInk3)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var leadingWell: some View {
        let shape = RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous)

        switch leading {
        case .glyph(let systemName):
            shape
                .fill(Color.circaWell)
                .frame(width: Circa.entryWell, height: Circa.entryWell)
                .overlay {
                    Image(systemName: systemName)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.circaInk3.opacity(0.7))
                }
                .overlay {
                    shape.strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
                }

        case .photo(let image):
            shape
                .fill(Color.circaMediaWell)
                .frame(width: Circa.entryWell, height: Circa.entryWell)
                .overlay {
                    if let image {
                        image
                            .resizable()
                            .scaledToFill()
                            .clipShape(shape)
                    }
                }

        case .photoContent(let content):
            shape
                .fill(Color.circaMediaWell)
                .frame(width: Circa.entryWell, height: Circa.entryWell)
                .overlay { content.clipShape(shape) }

        case .none:
            EmptyView()
        }
    }
}

// MARK: - Dock

struct CircaDockItem: Identifiable {
    let id: String
    let title: String
    let systemName: String
    let action: () -> Void

    init(title: String, systemName: String, action: @escaping () -> Void) {
        self.id = title
        self.title = title
        self.systemName = systemName
        self.action = action
    }
}

/// The logging dock. Four equal targets on a raised pill.
///
/// At accessibility sizes it **drops its labels** rather than truncating them,
/// and grows the targets — design.md rule 8, third clause. Four 56pt targets
/// with no text beats four truncated ones.
struct CircaDock: View {
    let items: [CircaDockItem]
    var isDisabled: Bool = false

    @Environment(\.dynamicTypeSize) private var typeSize

    private var hidesLabels: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 5) {
                        Image(systemName: item.systemName)
                            .font(.system(size: hidesLabels ? 22 : 17, weight: .medium))
                            .foregroundStyle(Color.circaInk2)

                        if !hidesLabels {
                            Text(item.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.circaInk2)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: hidesLabels ? Kit.dockItemHeightAX : Kit.dockItemHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.circaCard, in: shape)
        .overlay { shape.strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline) }
        .circaLift()
        .opacity(isDisabled ? 0.72 : 1)
        .disabled(isDisabled)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Circa.Radius.dock, style: .continuous)
    }
}

// MARK: - Gallery

#if DEBUG

/// Every shape in the kit on one page, built **only** from the kit — which is
/// Step 2a's own done-condition. Preview-only; nothing here is reachable from
/// the running app.
private struct CircaGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // The swatch check. `design.md` open item 5: the tokens resolve
                // off `UITraitCollection` while the app applies its own
                // light/dark choice with `.preferredColorScheme`. If the dark
                // preview below shows light swatches, that propagation is
                // broken and nothing else in this file can be trusted.
                VStack(alignment: .leading, spacing: 8) {
                    CircaSectionLabel("Tokens")
                    HStack(spacing: 6) {
                        swatch(.circaInk)
                        swatch(.circaInk3)
                        swatch(.circaAccent)
                        swatch(.circaCard)
                        swatch(.circaSunken)
                        swatch(.circaWell)
                        swatch(.circaBarTrack)
                        swatch(.circaDanger)
                    }
                }

                CircaHairline()

                CircaSectionHeader(title: "Daily targets", link: "Sources") {}

                VStack(alignment: .leading, spacing: 10) {
                    CircaSectionLabel("Certainty")
                    HStack(alignment: .bottom, spacing: 28) {
                        labelled("estimated") {
                            CircaEstimate("780", certainty: .estimated, font: .circaMonoLarge)
                        }
                        labelled("known") {
                            CircaEstimate("180", certainty: .known, font: .circaMonoLarge)
                        }
                        labelled("pending") {
                            CircaEstimate(nil, certainty: .pending, font: .circaMonoLarge)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    CircaSectionLabel("Surfaces")
                    CircaCard(.raised) {
                        VStack(alignment: .leading, spacing: 13) {
                            HStack(alignment: .firstTextBaseline) {
                                HStack(alignment: .firstTextBaseline, spacing: 7) {
                                    Text("1,020").font(.circaMonoLarge).monospacedDigit()
                                    Text("left").font(.circaRow).foregroundStyle(Color.circaInk2)
                                }
                                Spacer()
                                Text("1,380 of 2,400")
                                    .font(.circaMono)
                                    .monospacedDigit()
                                    .foregroundStyle(Color.circaInk3)
                            }
                            CircaMacroBars(
                                protein: .init(consumed: 81, target: 165),
                                carbs: .init(consumed: 134, target: 240),
                                fat: .init(consumed: 56, target: 80)
                            )
                        }
                    }

                    CircaCard(.sunken, radius: Circa.Radius.cardSmall) {
                        VStack(alignment: .leading, spacing: 6) {
                            CircaSectionLabel("Your week is ready")
                            Text("Trend weight down 0.4 kg. Your targets moved.")
                                .font(.circaRow)
                            HStack(spacing: 0) {
                                Button("See the week") {}.buttonStyle(.circa(.link))
                                Button("Not now") {}.buttonStyle(.circa(.quiet))
                            }
                            .padding(.leading, -10)
                        }
                    }

                    CircaCard(.danger, radius: Circa.Radius.cardSmall) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("chicken stew, a bowl of rice, a side salad")
                                .font(.circaEntryTitle)
                            Text("Couldn't reach Circa. Your words are saved — nothing to retype.")
                                .font(.circaBody)
                                .foregroundStyle(Color.circaDanger)
                            HStack(spacing: 8) {
                                Button("Try again") {}.buttonStyle(.circa(.primary))
                                Button("Delete") {}.buttonStyle(.circa(.quiet))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    CircaSectionLabel("Four tiers")
                    HStack(spacing: 10) {
                        Button("Looks right") {}.buttonStyle(.circa(.primary))
                        Button("Edit") {}.buttonStyle(.circa(.secondary))
                    }
                    Button("Confirm all 3") {}
                        .buttonStyle(.circa(.outline))
                        .frame(maxWidth: .infinity)
                }

                CircaHairline()

                VStack(alignment: .leading, spacing: 0) {
                    CircaSectionLabel("Entries")
                        .padding(.horizontal, Circa.Space.screenMargin)
                    CircaEntryRow(
                        title: "bread and tea",
                        calories: "420",
                        certainty: .estimated,
                        meta: "08:20 · 9P 48C 21F",
                        assumption: "1 assumption · 1 tbsp butter",
                        leading: .glyph("text.alignleft")
                    )
                    CircaEntryRow(
                        title: "chicken stew, a bowl of rice, a side salad",
                        calories: nil,
                        certainty: .pending,
                        meta: "estimating",
                        leading: .photo(nil),
                        isAnalysing: true
                    )
                    CircaEntryRow(
                        title: "whey shake",
                        calories: "180",
                        certainty: .known,
                        meta: "17:10 · 30P 8C 3F · saved",
                        leading: .glyph("bookmark")
                    )
                }
                .padding(.horizontal, -Circa.Space.screenMargin)

                CircaDock(items: [
                    CircaDockItem(title: "Text", systemName: "text.bubble") {},
                    CircaDockItem(title: "Camera", systemName: "camera") {},
                    CircaDockItem(title: "Gallery", systemName: "photo.on.rectangle") {},
                    CircaDockItem(title: "Saved", systemName: "bookmark") {}
                ])
            }
            .padding(Circa.Space.screenMargin)
        }
        .circaPaper()
    }

    private func swatch(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(color)
            .frame(height: 34)
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.circaRule, lineWidth: Circa.Rule.hairline)
            }
    }

    private func labelled<Content: View>(
        _ caption: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            content()
            Text(caption).font(.circaMono).foregroundStyle(Color.circaInk3)
        }
    }
}

#Preview("Kit · light") {
    CircaGallery()
}

#Preview("Kit · dark") {
    CircaGallery()
        .preferredColorScheme(.dark)
}

#Preview("Kit · AX3") {
    CircaGallery()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Kit · Arabic RTL") {
    CircaGallery()
        .environment(\.layoutDirection, .rightToLeft)
}

#endif
