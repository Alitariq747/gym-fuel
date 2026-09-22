import SwiftUI

enum MainMenuDestination: CaseIterable {
    case week
    case weight
    case targets
    case settings

    var title: String {
        switch self {
        case .week: return "Week"
        case .weight: return "Weight"
        case .targets: return "Your targets"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .week: return "calendar"
        case .weight: return "chart.xyaxis.line"
        case .targets: return "scope"
        case .settings: return "gearshape"
        }
    }
}

struct MainMenuSheet: View {
    let onSelect: (MainMenuDestination) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        CircaSectionLabel("Your journal")
                        Text("Menu")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.circaInk)
                            .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                            .background(Color.circaCard, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close menu")
                }

                VStack(spacing: 0) {
                    ForEach(MainMenuDestination.allCases, id: \.self) { destination in
                        Button { onSelect(destination) } label: {
                            ProfileSettingsRow(
                                title: destination.title,
                                systemImage: destination.symbol,
                                value: ""
                            )
                        }
                        .buttonStyle(.plain)
                        if destination != .settings {
                            CircaHairline(weight: .inCard)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(ProfileCardBackground())
            }
            .padding(Circa.Space.screenMargin)
        }
        .circaPaper()
    }
}
