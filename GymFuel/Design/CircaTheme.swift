//
//  CircaTheme.swift
//  GymFuel
//
//  The design tokens. Specified in `design.md`, which is the source of truth —
//  if a value here and a value there disagree, the doc wins and this file is the bug.
//
//  Values only. Shapes (cards, buttons, rows, the certainty rule) live in the
//  component kit, not here.
//
//  Two things to know before editing:
//
//  1. Dark is a designed twin, not an inversion. Warm near-black, never #000000,
//     or the paper character dies.
//  2. Fonts are built on text styles so Dynamic Type works to AX3 without
//     per-screen effort. Adding a `Font.system(size:)` here undoes that.
//

import SwiftUI
import UIKit

// MARK: - Adaptive plumbing

private extension UIColor {
    convenience init(circaHex hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Resolves against the trait collection, so a token follows both the system
/// appearance and the app's own light/dark override.
private func circaAdaptive(light: UInt32, dark: UInt32) -> Color {
    Color(UIColor { traits in
        UIColor(circaHex: traits.userInterfaceStyle == .dark ? dark : light)
    })
}

// MARK: - Palette

extension Color {

    // Ink — text, fills, bars.
    /// Primary text and filled surfaces. 16.8:1 on paper, 15.9:1 in dark.
    static let circaInk = circaAdaptive(light: 0x1A1917, dark: 0xF2F0E8)
    /// Secondary text and body copy. 7.3:1 on paper.
    static let circaInk2 = circaAdaptive(light: 0x56534C, dark: 0xACA79B)
    /// Mono metadata and captions. 5.1:1 on paper, 5.0:1 in dark.
    static let circaInk3 = circaAdaptive(light: 0x6E6B64, dark: 0x8B8679)

    // Accent — assumptions, links, ochre marks.
    /// 5.0:1 on paper, 8.4:1 in dark. Safe for body text.
    static let circaAccent = circaAdaptive(light: 0x8F6420, dark: 0xD9A94E)
    /// 3.8:1 on paper — large numerals and fills ONLY, never body text.
    static let circaAccentLarge = circaAdaptive(light: 0xA8762A, dark: 0xD9A94E)

    // Failure. A warm brick, deliberately not a system red — see design.md rule 5.
    /// 6.4:1 on paper.
    static let circaDanger = circaAdaptive(light: 0xA03A28, dark: 0xE08571)
    static let circaDangerGround = circaAdaptive(light: 0xFCF6F3, dark: 0x241A16)
    static let circaDangerBorder = circaAdaptive(light: 0xE8CFC7, dark: 0x3D2721)

    // Surfaces.
    /// Raised — cards, the dock, the summary block.
    static let circaCard = circaAdaptive(light: 0xFFFFFF, dark: 0x1F1D18)
    /// Recessed — the check-in prompt, inline notes.
    static let circaSunken = circaAdaptive(light: 0xEFEBDF, dark: 0x211F19)
    /// The ground a photo or its placeholder sits on.
    static let circaMediaWell = circaAdaptive(light: 0xEAE6DA, dark: 0x262319)
    /// The ground behind a text entry's glyph. Distinct from `circaMediaWell`:
    /// this one takes a `circaCardBorder` hairline, a photo well never does.
    static let circaWell = circaAdaptive(light: 0xF1EDE2, dark: 0x1F1D18)
    /// The unfilled part of a macro bar. Lighter than `circaRule` in both
    /// themes — a bar track read as a divider is the drift this prevents.
    static let circaBarTrack = circaAdaptive(light: 0xE8E4D8, dark: 0x332F26)

    // Lines.
    /// Section dividers, between-block rules.
    static let circaRule = circaAdaptive(light: 0xE3DFD3, dark: 0x2D2A23)
    /// Dividers *inside* a card — lighter than `circaRule`.
    static let circaRuleSoft = circaAdaptive(light: 0xF0ECE0, dark: 0x26231D)
    /// The hairline around a card.
    static let circaCardBorder = circaAdaptive(light: 0xE9E5D9, dark: 0x2D2A23)

    /// The certainty rule. See `design.md` rule 1 — this is the mark that makes
    /// the name mean something, and it carries three states, not two.
    static let circaDotted = circaAdaptive(light: 0x9A9488, dark: 0x6B6659)

    // Paper. Not used directly as a fill — the body is a gradient, below.
    static let circaPaperTop = circaAdaptive(light: 0xFBFAF6, dark: 0x171612)
    static let circaPaperBottom = circaAdaptive(light: 0xF4F1E8, dark: 0x100F0C)
}

// MARK: - Paper

extension LinearGradient {
    /// The body background. Paper is a two-stop vertical gradient in both themes,
    /// so it is declared once here rather than re-typed per screen.
    static let circaPaper = LinearGradient(
        colors: [.circaPaperTop, .circaPaperBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Type

extension Font {

    /// Screen titles — "Today", "Settings", "Circa Pro".
    static let circaTitle = Font.system(.title).weight(.semibold)
    /// A timeline entry's title, which is the user's own sentence.
    static let circaEntryTitle = Font.system(.body).weight(.medium)
    /// List and settings rows.
    static let circaRow = Font.system(.callout)
    /// Explanatory body copy.
    static let circaBody = Font.system(.subheadline)
    /// Small print under a control.
    static let circaCaption = Font.system(.footnote)

    /// Machine metadata — times, macros, assumptions, quota, section labels.
    static let circaMono = Font.system(.caption2, design: .monospaced)
    /// A number that carries weight in a row — an entry's calories.
    static let circaMonoValue = Font.system(.callout, design: .monospaced).weight(.semibold)
    /// A number that leads a card — a day total.
    static let circaMonoLarge = Font.system(.title3, design: .monospaced).weight(.semibold)
}

// MARK: - Metrics

enum Circa {

    enum Radius {
        /// Major cards — the day summary and the paywall tray.
        static let card: CGFloat = 20
        /// Inline cards — an assumption row, a failure card.
        static let cardSmall: CGFloat = 16
        /// Entry thumbnails and small square wells.
        static let thumb: CGFloat = 11
        static let button: CGFloat = 14
        static let pill: CGFloat = 22
        /// `LogActionDock`.
        static let dock: CGFloat = 34
    }

    enum Space {
        /// Standard screen gutter.
        static let screenMargin: CGFloat = 20
        /// Gutter when the content is a full-bleed card row.
        static let screenMarginWide: CGFloat = 16
        static let cardInset: CGFloat = 18
        static let rowGap: CGFloat = 11
    }

    /// Apple's floor, and `design.md`'s — no exceptions.
    static let minHitTarget: CGFloat = 44

    /// Mono section labels are uppercased and tracked. `Font` cannot carry
    /// tracking, so it is applied at the call site with `.tracking(_:)`.
    static let sectionLabelTracking: CGFloat = 1.4

    /// Display numerals, larger than any text style can express. These are base
    /// sizes — scale them with `@ScaledMetric(relativeTo: .largeTitle)` in the
    /// view that uses them, or Dynamic Type stops at these values.
    enum Display {
        static let entryTotal: CGFloat = 44
    }

    enum Rule {
        /// Stroke width of the certainty rule.
        static let certaintyWidth: CGFloat = 1.5
        /// Hairline for card borders and dividers.
        static let hairline: CGFloat = 1
    }
}
