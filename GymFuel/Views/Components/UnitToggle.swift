//
//  UnitToggle.swift
//  GymFuel
//
//  One segmented unit control for every screen that picks a height or a weight.
//  There were five copies of this before, each drifting on corner radius, label
//  wording and whether the selected segment took a border.
//

import SwiftUI

struct UnitToggle<Value: Hashable>: View {
    let options: [Value]
    let label: (Value) -> String
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.self) { segment($0) }
        }
        .padding(3)
        .background(Color.circaSunken, in: RoundedRectangle(cornerRadius: Circa.Radius.button, style: .continuous))
    }

    private func segment(_ option: Value) -> some View {
        let isSelected = option == selection
        let shape = RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous)

        return Button {
            selection = option
        } label: {
            Text(label(option))
                .font(.circaRow.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.circaInk : Color.circaInk2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 14)
                .frame(minHeight: Circa.minHitTarget)
                .background(isSelected ? Color.circaCard : Color.clear, in: shape)
                .overlay { if isSelected { shape.strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline) } }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

extension Binding where Value == String {
    /// The stored unit preference as a unit. `BodyWeightUnit` persists by raw
    /// value so `@AppStorage` can hold it; the toggles want the unit itself.
    var asBodyWeightUnit: Binding<BodyWeightUnit> {
        Binding<BodyWeightUnit>(
            get: { BodyWeightUnit(rawValue: wrappedValue) ?? .kilograms },
            set: { wrappedValue = $0.rawValue }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        UnitToggle(options: BodyWeightUnit.allCases, label: { $0.shortLabel }, selection: .constant(.kilograms))
        UnitToggle(options: BodyHeightUnit.allCases, label: { $0.shortLabel }, selection: .constant(.feetInches))
    }
    .padding(Circa.Space.screenMargin)
    .frame(maxHeight: .infinity)
    .circaPaper()
}
