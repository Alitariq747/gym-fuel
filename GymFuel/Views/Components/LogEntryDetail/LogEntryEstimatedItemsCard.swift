import SwiftUI

struct EstimatedItemsCard: View {
    let items: [EstimatedItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Estimated Breakdown")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Food items LiftEats used to build this estimate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(items, id: \.self) { item in
                    EstimatedItemRow(item: item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EstimatedItemRow: View {
    let item: EstimatedItem
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    private var itemTitle: String {
        item.quantity.isEmpty ? item.name : "\(item.name) (\(item.quantity))"
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.quaternaryLabel)
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Text(itemTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                if isExpanded, !item.estimatedComponents.isEmpty {
                    Divider()

                    VStack(spacing: 8) {
                        ForEach(item.estimatedComponents, id: \.self) { component in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(component.name)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 8)

                                Text(component.estimatedAmount)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isExpanded ? "Collapses estimated components" : "Expands estimated components")
    }
}
