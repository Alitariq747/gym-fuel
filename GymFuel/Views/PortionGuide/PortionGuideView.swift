//
//  PortionGuideView.swift
//  GymFuel
//

import SwiftUI

/// Weights only, never calories or macros: design.md, *Portion guide*.
struct PortionGuideView: View {
    @StateObject private var store = PortionGuideStore()
    @EnvironmentObject private var authManager: FirebaseAuthManager
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .callout) private var thumbnailSize: CGFloat = 48

    private let checkingSteps = [
        "Log the meal as usual.",
        "Open it. The breakdown lists each part with its weight, like rice 300 g and chicken 120 g.",
        "Find each part in this guide. If your plate had more or less, tap the pencil and change the amount.",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("What amounts look like, weighed. Use it to check the amounts in Circa's breakdown against your plate.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)

                    checkingCard
                    meansByCard

                    ForEach(store.guide.sections) { section in
                        GuideRowsCard(title: section.category.name, items: section.foods) { food in
                            NavigationLink {
                                PortionGuideFoodView(food: food, credit: store.guide.credit)
                            } label: {
                                foodRow(food)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let userId = authManager.user?.uid {
                        GuideRequestCard(userId: userId)
                    }

                    sources
                }
                .padding(Circa.Space.screenMargin)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Portion guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CircaCloseButton { dismiss() }
                }
            }
            .circaPaper()
        }
        .task { await store.refresh() }
    }

    private var checkingCard: some View {
        CircaCard(.sunken) {
            VStack(alignment: .leading, spacing: 10) {
                CircaSectionLabel("Checking a breakdown")
                ForEach(Array(checkingSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.circaMono)
                            .foregroundStyle(Color.circaInk3)
                        Text(step)
                            .font(.circaBody)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var meansByCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CircaSectionLabel("What Circa means by")
            CircaCard(inset: EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)) {
                NavigationLink {
                    PortionGuideSizesView(guide: store.guide)
                } label: {
                    HStack(spacing: 12) {
                        CircaSymbolWell(symbol: "cup.and.saucer")
                        Text("Plates, bowls, spoons and oil")
                            .font(.circaRow)
                            .foregroundStyle(Color.circaInk)
                        Spacer(minLength: 0)
                        chevron
                    }
                    .padding(.vertical, 10)
                    .frame(minHeight: Circa.minHitTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func foodRow(_ food: GuideFood) -> some View {
        HStack(spacing: 12) {
            GuideImage(image: food.thumbnail)
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous))
            Text(food.name)
                .font(.circaRow)
                .foregroundStyle(Color.circaInk)
            Spacer(minLength: 0)
            chevron
        }
        .padding(.vertical, 10)
        .frame(minHeight: Circa.minHitTarget)
        .contentShape(Rectangle())
    }

    private var chevron: some View {
        Image(systemName: "chevron.forward")
            .font(.circaCaption)
            .foregroundStyle(Color.circaInk3)
            .accessibilityHidden(true)
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let credit = store.guide.credit {
                Text(credit)
            }
            if let source = store.guide.source {
                Text("Circa's amounts: \(source).")
            }
        }
        .font(.circaCaption)
        .foregroundStyle(Color.circaInk3)
        .fixedSize(horizontal: false, vertical: true)
    }
}
