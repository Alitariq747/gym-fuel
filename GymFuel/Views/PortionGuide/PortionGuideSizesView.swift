//
//  PortionGuideSizesView.swift
//  GymFuel
//

import SwiftUI

struct PortionGuideSizesView: View {
    let guide: PortionGuide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("When you write \"a plate\", \"a bowl\" or \"a little oil\", this is what Circa counts.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                GuideRowsCard(title: "Plates, bowls, mugs and glasses", items: guide.containers) { container in
                    SizeRow(name: container.name, value: GuideFormat.size(of: container))
                }
                GuideRowsCard(title: "Spoons", items: guide.spoons) { spoon in
                    SizeRow(name: spoon.name, value: GuideFormat.ml(spoon.ml))
                }
                GuideRowsCard(title: "Oil and fat", items: guide.fatLevels) { level in
                    SizeRow(name: level.name, value: GuideFormat.oil(level), detail: level.looks)
                }
            }
            .padding(Circa.Space.screenMargin)
        }
        .navigationTitle("What Circa means by")
        .navigationBarTitleDisplayMode(.inline)
        .circaPaper()
    }
}

struct SizeRow: View {
    let name: String
    let value: String
    var detail: String? = nil

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let isStacked = typeSize.isAccessibilitySize
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        VStack(alignment: .leading, spacing: 4) {
            layout {
                Text(name)
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk)
                if !isStacked { Spacer(minLength: 8) }
                Text(value)
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk2)
            }
            if let detail {
                Text(detail)
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
