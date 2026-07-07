import SwiftUI

struct ProfileSubscriptionSection: View {
    let currentPlan: SubscriptionPlan
    let isLoading: Bool
    let onOpenPaywall: () -> Void
    let onOpenManagement: () -> Void
    let onRestorePurchases: () -> Void

    private var isPro: Bool {
        currentPlan == .pro
    }

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Subscription", systemImage: "crown.fill")

            VStack(spacing: 0) {
                Button(action: primaryAction) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.liftEatsCoral.opacity(0.12))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "crown.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color.liftEatsCoral)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Plan")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(currentPlan.profileDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(currentPlan.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(16)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Divider()
                    .padding(.leading, 82)

                Button(action: onRestorePurchases) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.fuelBlue.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.fuelBlue)
                            )

                        Text("Restore Purchases")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .background(ProfileCardBackground())
        }
        .padding(.horizontal)
    }

    private func primaryAction() {
        if isPro {
            onOpenManagement()
        } else {
            onOpenPaywall()
        }
    }
}
