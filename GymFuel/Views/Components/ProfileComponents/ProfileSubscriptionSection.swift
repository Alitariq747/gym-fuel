import SwiftUI

struct ProfileSubscriptionSection: View {
    let status: SubscriptionStatus
    let isSyncingStatus: Bool
    let onOpenPaywall: () -> Void
    let onManageSubscription: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Subscription", systemImage: "crown")

            Button {
                if status.hasProAccess {
                    onManageSubscription()
                } else {
                    onOpenPaywall()
                }
            } label: {
                HStack(spacing: 14) {
                    icon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(ProfileSubscriptionCopy.title(for: status))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let subtitle = ProfileSubscriptionCopy.subtitle(for: status) {
                            Text(subtitle)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 12)

                    if isSyncingStatus {
                        ProgressView()
                            .controlSize(.small)
                    } else if let badge = ProfileSubscriptionCopy.badge(for: status) {
                        Text(badge)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(statusTint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(statusTint.opacity(0.12), in: Capsule())
                    }

                    HStack(spacing: 4) {
                        Text(ProfileSubscriptionCopy.actionLabel(for: status))
                            .font(.caption2.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(16)
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(statusTint.opacity(0.14), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    private var icon: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(statusTint.opacity(0.12))
            .frame(width: 52, height: 52)
            .overlay(
                Image(systemName: status.hasProAccess ? "crown.fill" : "sparkles")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(statusTint)
            )
    }

    private var statusTint: Color {
        switch status.state {
        case .free:
            return Color.liftEatsCoral
        case .trial:
            return Color.liftEatsCoral
        case .active:
            return Color.fuelGreen
        }
    }
}

private enum ProfileSubscriptionCopy {
    static func title(for status: SubscriptionStatus) -> String {
        switch status.state {
        case .free:
            return "Get LiftEats Pro"
        case .trial:
            return "Pro trial active"
        case .active:
            switch status.productKind {
            case .monthly:
                return "LiftEats Pro Monthly"
            case .yearly:
                return "LiftEats Pro Yearly"
            case .unknown:
                return "LiftEats Pro"
            }
        }
    }

    static func subtitle(for status: SubscriptionStatus) -> String? {
        switch status.state {
        case .free:
            return "Unlock AI meal and workout logging"
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
