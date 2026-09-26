//
//  BodyHeight.swift
//  GymFuel
//

import Foundation

/// The unit a height is entered and displayed in. Storage is always
/// centimetres; this only affects the wheels and the label.
enum BodyHeightUnit: String, CaseIterable, Identifiable, Sendable {
    case centimeters
    case feetInches

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .centimeters: "cm"
        case .feetInches: "ft/in"
        }
    }
}

/// Conversion, rounding and range for body heights.
enum BodyHeight {
    static let centimetersPerInch: Double = 2.54

    /// The range the wheels offer. Reasonable for most adults; widen here and
    /// the feet and inches rows follow, because they are derived from it.
    static let minimumCentimeters: Double = 120
    static let maximumCentimeters: Double = 220

    static func inches(fromCentimeters centimeters: Double) -> Double {
        centimeters / centimetersPerInch
    }

    static func centimeters(fromInches inches: Double) -> Double {
        inches * centimetersPerInch
    }

    static func clampedToRange(_ centimeters: Double) -> Double {
        min(max(centimeters, minimumCentimeters), maximumCentimeters)
    }
}

/// What the height wheels offer in one unit, and how their rows turn back into
/// centimetres.
///
/// Centimetres are the stored value and feet and inches are derived from them,
/// rather than the two being kept in step by a pair of `onChange` handlers. The
/// old arrangement let a foot-and-inch height be saved without ever being
/// clamped: 8′ 9″ stored 266 cm.
struct HeightWheel {
    let unit: BodyHeightUnit

    init(_ unit: BodyHeightUnit) {
        self.unit = unit
    }

    // MARK: - Rows

    var centimeterRange: ClosedRange<Int> {
        Int(BodyHeight.minimumCentimeters.rounded(.up))...Int(BodyHeight.maximumCentimeters.rounded(.down))
    }

    /// Derived, so a foot mark the centimetre range cannot reach is never
    /// offered. At 120–220 cm that is 3′–7′; a hand-written `3...8` offered an
    /// 8′ row that could only snap back.
    var feetRange: ClosedRange<Int> {
        lowestInches / 12...highestInches / 12
    }

    /// The inches available at one foot mark. **Both ends of the range are
    /// partial feet** — 120 cm is 3′ 11″ and 220 cm is 7′ 3″ — so those two
    /// marks offer fewer rows than the twelve in between. Offering all twelve
    /// is what made the wheel snap back when the user scrolled past the end.
    func inchRange(atFeet feet: Int) -> ClosedRange<Int> {
        let base = feet * 12
        let lower = base >= lowestInches ? 0 : lowestInches - base
        let upper = base + 11 <= highestInches ? 11 : highestInches - base
        return lower...max(lower, upper)
    }

    private var lowestInches: Int { totalInches(BodyHeight.minimumCentimeters) }
    private var highestInches: Int { totalInches(BodyHeight.maximumCentimeters) }

    private func totalInches(_ centimeters: Double) -> Int {
        Int(BodyHeight.inches(fromCentimeters: centimeters).rounded())
    }

    // MARK: - Conversion

    func feetInches(_ centimeters: Int) -> (feet: Int, inches: Int) {
        let total = totalInches(Double(clamped(centimeters)))
        return (total / 12, total % 12)
    }

    /// The single write path back into centimetres.
    func centimeters(feet: Int, inches: Int) -> Int {
        clamped(Int(BodyHeight.centimeters(fromInches: Double(feet * 12 + inches)).rounded()))
    }

    func clamped(_ centimeters: Int) -> Int {
        min(max(centimeters, centimeterRange.lowerBound), centimeterRange.upperBound)
    }

    func displayString(_ centimeters: Int) -> String {
        switch unit {
        case .centimeters:
            return "\(clamped(centimeters)) cm"
        case .feetInches:
            let parts = feetInches(centimeters)
            return "\(parts.feet)′ \(parts.inches)″"
        }
    }
}
