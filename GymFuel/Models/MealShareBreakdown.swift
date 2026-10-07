import Foundation

/// The breakdown as the share card lists it — `design.md`, *Share card (7k)*.
/// Past `maxRows` the smaller items fold into one "+ N more" row that keeps their
/// calories, so the rows always add up to the card's total.
struct MealShareBreakdown: Equatable {
    struct Row: Equatable, Identifiable {
        let id: String
        let name: String
        let amount: MealAmount?
        /// `nil` is a descriptive item, listed without a number.
        let macros: Macros?
        let source: MealProvenance
    }

    static let maxRows = 4

    let rows: [Row]
    let moreCount: Int
    /// `nil` when none of the folded items carries a number.
    let moreMacros: Macros?

    /// `nil` when the user removed every item.
    init?(_ breakdown: MealBreakdown, calculator: MealBreakdownCalculator = MealBreakdownCalculator()) {
        let all = breakdown.items
            .filter { $0.amount?.effectiveQuantity != 0 }
            .map { Row(id: $0.id, name: $0.name, amount: $0.amount, macros: calculator.contribution(of: $0), source: $0.resolvedSource) }
        guard !all.isEmpty else { return nil }

        guard all.count > Self.maxRows else {
            rows = all
            moreCount = 0
            moreMacros = nil
            return
        }

        // Largest first, ties in meal order — the same ranking as the timeline's assumption line.
        let ranked = all.indices.sorted {
            let (a, b) = (all[$0].macros?.calories ?? 0, all[$1].macros?.calories ?? 0)
            return a != b ? a > b : $0 < $1
        }
        let kept = Set(ranked.prefix(Self.maxRows - 1))
        let folded = all.indices.filter { !kept.contains($0) }.compactMap { all[$0].macros }

        rows = all.indices.filter(kept.contains).map { all[$0] }
        moreCount = all.count - kept.count
        moreMacros = folded.isEmpty ? nil : folded.reduce(.zero, +)
    }
}
