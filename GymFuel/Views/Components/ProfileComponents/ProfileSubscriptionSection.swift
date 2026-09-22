import SwiftUI

struct ProfileSubscriptionSection: View {
    let status: SubscriptionStatus
    let isSyncingStatus: Bool
    let onOpenPaywall: () -> Void
    let onManageSubscription: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Subscription")

            Button {
                if status.hasProAccess {
                    onManageSubscription()
                } else {
                    onOpenPaywall()
                }
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        icon

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ProfileSubscriptionCopy.title(for: status))
                                .font(.circaRow)
                                .foregroundStyle(Color.circaInk)

                            if let subtitle = ProfileSubscriptionCopy.subtitle(for: status) {
                                Text(subtitle)
                                    .font(.circaCaption)
                                    .foregroundStyle(Color.circaInk2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 0)
                    }

                    CircaHairline(weight: .inCard)

                    HStack(spacing: 8) {
                        if isSyncingStatus {
                            ProgressView()
                                .controlSize(.small)
                        } else if let badge = ProfileSubscriptionCopy.badge(for: status) {
                            Text(badge)
                                .font(.circaMono)
                                .foregroundStyle(Color.circaAccent)
                        }

                        Spacer(minLength: 0)
                        Text(ProfileSubscriptionCopy.actionLabel(for: status))
                            .font(.circaMono)
                        Image(systemName: "chevron.right")
                            .font(.circaCaption)
                    }
                    .foregroundStyle(Color.circaInk2)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal, Circa.Space.screenMargin)
    }

    private var icon: some View {
        RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous)
            .fill(Color.circaWell)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: status.hasProAccess ? "crown.fill" : "sparkles")
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk2)
            )
    }
}

private enum ProfileSubscriptionCopy {
    static func title(for status: SubscriptionStatus) -> String {
        switch status.state {
        case .free:
            return "Get Circa Pro"
        case .trial:
            return "Pro trial active"
        case .active:
            switch status.productKind {
            case .monthly:
                return "Circa Pro Monthly"
            case .yearly:
                return "Circa Pro Yearly"
            case .unknown:
                return "Circa Pro"
            }
        }
    }

    static func subtitle(for status: SubscriptionStatus) -> String? {
        switch status.state {
        case .free:
            return "Unlock AI meal logging"
        case .trial, .active:
            return nil
        }
    }

    static func badge(for status: SubscriptionStatus) -> String? {
        switch status.state {
        case .free:
            return nil
        case .trial:
            return "Trial"
        case .active:
            return "Pro"
        }
    }

    static func actionLabel(for status: SubscriptionStatus) -> String {
        status.hasProAccess ? "Manage" : "Upgrade"
    }
}
