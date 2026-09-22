import SwiftUI

extension SavedMeal {
    var searchText: String {
        let itemWords = breakdown?.items.flatMap { item in
            [item.name, item.assumption ?? ""] + item.components.flatMap { [$0.name, $0.assumption ?? ""] }
        } ?? []
        return ([name, description ?? ""] + (assumptions ?? []) + itemWords).joined(separator: " ")
    }
}

struct SavedMealCard: View {
    let meal: SavedMeal
    var actionTitle: String

    private var title: String {
        let name = meal.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        return meal.description?.isEmpty == false ? meal.description ?? "Saved meal" : "Saved meal"
    }

    private var detail: String? {
        let items = meal.breakdown?.isSupported == true ? meal.breakdown?.items.map(\.name) : nil
        if let items, !items.isEmpty { return items.joined(separator: " · ") }
        let description = meal.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        return description?.isEmpty == false && description != title ? description : nil
    }

    private var provenance: String {
        if meal.macrosProvenance == .userTotal { return "You set this total" }
        guard let breakdown = meal.breakdown, breakdown.isSupported else { return "Saved total" }
        let nodes = breakdown.items.flatMap { [$0.amount?.isAdjusted == true] + $0.components.map { $0.amount?.isAdjusted == true } }
        let adjusted = nodes.contains(true)
        if meal.macrosProvenance == .reference {
            return adjusted ? "Reference values · your amounts" : "Reference values"
        }
        return adjusted ? "Estimated · your amounts" : "Estimated breakdown"
    }

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(title)
                        .font(.circaRow.weight(.semibold))
                        .foregroundStyle(Color.circaInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    CircaEstimate(
                        "\(Int(meal.macros.calories.rounded())) kcal",
                        certainty: meal.macrosProvenance == .userTotal || meal.macrosProvenance == .reference ? .known : .estimated
                    )
                }
                if let detail {
                    Text(detail)
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text(provenance)
                        .foregroundStyle(Color.circaAccent)
                    Text("·")
                    Text("P \(Int(meal.macros.protein.rounded()))  C \(Int(meal.macros.carbs.rounded()))  F \(Int(meal.macros.fat.rounded()))")
                        .foregroundStyle(Color.circaInk3)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.circaInk3)
                }
                .font(.circaMono)
                .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(actionTitle)
    }
}
