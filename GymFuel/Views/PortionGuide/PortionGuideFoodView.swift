//
//  PortionGuideFoodView.swift
//  GymFuel
//

import SwiftUI

/// Weights only, never calories or macros: design.md, *Portion guide*.
struct PortionGuideFoodView: View {
    let food: GuideFood
    let credit: String?

    @State private var selected: Int

    init(food: GuideFood, credit: String?) {
        self.food = food
        self.credit = credit
        // Opens on the photo its row showed.
        _selected = State(initialValue: food.photos?.firstIndex { $0.image == food.thumbnail } ?? 0)
    }

    private var photos: [GuidePhoto] { food.photos ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !photos.isEmpty {
                    photoViewer
                }
                if !food.amounts.isEmpty {
                    GuideRowsCard(title: "What Circa means by", items: food.amounts) { amount in
                        SizeRow(name: amount.label, value: GuideFormat.grams(amount.grams))
                    }
                }
                if let note = food.note {
                    Text(note)
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !photos.isEmpty, let credit {
                    Text(credit)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Circa.Space.screenMargin)
        }
        .navigationTitle(food.name)
        .navigationBarTitleDisplayMode(.inline)
        .circaPaper()
    }

    private var photoViewer: some View {
        VStack(alignment: .leading, spacing: 12) {
            TabView(selection: $selected) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    GuideImage(image: photo.image, contentMode: .fit)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .aspectRatio(3 / 2, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous))

            if let grams = photos.indices.contains(selected) ? photos[selected].grams : nil {
                Text(GuideFormat.grams(grams))
                    .font(.circaMonoLarge)
                    .foregroundStyle(Color.circaInk)
            } else {
                Text("The weight of each is printed on the photo.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if photos.count > 1 {
                HStack(spacing: 8) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                        thumbnail(photo, isSelected: index == selected) {
                            withAnimation { selected = index }
                        }
                    }
                }
            }
        }
    }

    private func thumbnail(_ photo: GuidePhoto, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous)
        return Button(action: action) {
            GuideImage(image: photo.image)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(shape)
                .overlay {
                    if isSelected { shape.strokeBorder(Color.circaInk, lineWidth: 2) }
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(photo.grams.map { GuideFormat.grams($0) } ?? food.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
