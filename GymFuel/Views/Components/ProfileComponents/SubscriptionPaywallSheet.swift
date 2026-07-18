import RevenueCat
import SwiftUI

struct SubscriptionPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel

    private let privacyURL = URL(string: "https://alitariq747.github.io/lifteats-legal/privacy-policy")!
    private let termsURL = URL(string: "https://alitariq747.github.io/lifteats-legal/terms")!

    private var selectedPackage: Package? {
        subscriptionViewModel.selectedPackage
    }

    private var features: [(emoji: String, title: String, detail: String)] {
        [
            ("🥗", "Food logging", "Log meals with text or photos in seconds."),
            ("🏋️", "Exercise logging", "Track workouts without breaking your flow."),
            ("⚡️", "Very low friction", "Built for quick logging throughout the day."),
            ("🎯", "Goal-based insights", "See feedback shaped around your current goal."),
            ("🏆", "Meal scoring", "Understand how each meal fits your plan."),
            ("✨", "Quick insights", "Get fast macro estimates and practical guidance."),
            ("🔔", "Smart reminders", "Stay consistent with gentle local nudges."),
        ]
    }

    var body: some View {
        ZStack {
            paywallBackground

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroSection
                        featureList
                        restoreAndLegalSection
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)
                }

                purchaseSection
            }
        }
        .task {
            await subscriptionViewModel.loadPaywallPackages()
        }
    }

    private var paywallBackground: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.liftEatsCoral.opacity(0.18),
                    Color(.systemBackground).opacity(0.2),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.liftEatsCoral.opacity(0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 38)
                .offset(x: 140, y: -180)
        }
    }

    private var headerBar: some View {
        HStack {
            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.top, 16)
        }
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .shadow(color: Color.liftEatsCoral.opacity(0.25), radius: 18, y: 10)

            Text("Access LiftEats Entirely")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text("Log faster, understand your macros, and keep your nutrition aligned with your goal.")
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var featureList: some View {
        VStack(spacing: 10) {
            ForEach(features, id: \.title) { feature in
                HStack(spacing: 12) {
                    Text(feature.emoji)
                        .font(.title3)
                        .frame(width: 42, height: 42)
                        .background(Color(.secondarySystemBackground), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(feature.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var restoreAndLegalSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    let didRestore = await subscriptionViewModel.restorePurchases()
                    if didRestore {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if subscriptionViewModel.isRestoring {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                        Text("Restore Subscription")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(Color(.secondarySystemBackground), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(subscriptionViewModel.isPurchasing || subscriptionViewModel.isRestoring)

            HStack(spacing: 8) {
                Link("Privacy Policy", destination: privacyURL)
                Text("·")
                    .foregroundStyle(.tertiary)
                Link("Terms of Service", destination: termsURL)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let errorMessage = subscriptionViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.fuelRed)
                    .padding(.horizontal, 12)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.12), radius: 20, y: -4)

                VStack(spacing: 10) {
                    packageOptions
                    continueButton
                    renewalFooter
                }
                .padding(16)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var packageOptions: some View {
        if subscriptionViewModel.isLoading {
            ProgressView()
                .padding(.vertical, 28)
        } else if subscriptionViewModel.paywallPackages.isEmpty {
            Text("Subscription options are unavailable. Please try again.")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 20)
        } else {
            VStack(spacing: 10) {
                ForEach(subscriptionViewModel.paywallPackages, id: \.identifier) { package in
                    packageCard(for: package)
                }
            }
        }
    }

    private func packageCard(for package: Package) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        let isYearly = package.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier

        return Button {
            guard subscriptionViewModel.isPurchasing == false,
                  subscriptionViewModel.isRestoring == false else { return }
            subscriptionViewModel.selectPackage(package)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.liftEatsCoral : Color.secondary.opacity(0.6))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Pro Yearly" : "Pro Monthly")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)

                        if isYearly {
                            Text("Best value")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.liftEatsCoral, in: Capsule())
                        }
                    }

                    Text(packageSubtitle(for: package))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(package.localizedPriceString)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.primary)

                    Text(isYearly ? "/ year" : "/ month")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? Color.liftEatsCoral.opacity(0.10) : Color(.secondarySystemBackground).opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Color.liftEatsCoral : Color.black.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(subscriptionViewModel.isPurchasing || subscriptionViewModel.isRestoring)
    }

    private var continueButton: some View {
        Button {
            Task {
                let didPurchase = await subscriptionViewModel.purchaseSelectedPackage()
                if didPurchase {
                    dismiss()
                }
            }
        } label: {
            HStack {
                Spacer()

                if subscriptionViewModel.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(continueButtonTitle)
                        .font(.headline.weight(.bold))
                }

                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(Color.liftEatsCoral, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.liftEatsCoral.opacity(0.28), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(
            selectedPackage == nil ||
            subscriptionViewModel.isLoading ||
            subscriptionViewModel.isPurchasing ||
            subscriptionViewModel.isRestoring
        )
        .opacity(selectedPackage == nil ? 0.55 : 1)
    }

    private var continueButtonTitle: String {
        guard let selectedPackage else { return "Continue" }
        return subscriptionViewModel.isEligibleForTrial(selectedPackage) ? "Start 3-day free trial" : "Continue"
    }

    private var renewalFooter: some View {
        Text(selectedPackage.map(footerText(for:)) ?? "Subscription renews automatically unless cancelled at least 24 hours before renewal.")
            .font(.caption2)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
    }

    private func packageSubtitle(for package: Package) -> String {
        if subscriptionViewModel.isEligibleForTrial(package) {
            return "3-day free trial available"
        }

        return billingText(for: package)
    }

    private func billingText(for package: Package) -> String {
        let isYearly = package.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier
        return "\(package.localizedPriceString) \(isYearly ? "per year" : "per month")"
    }

    private func footerText(for package: Package) -> String {
        let isYearly = package.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier

        if subscriptionViewModel.isEligibleForTrial(package) {
            return "3-day free trial, then \(package.localizedPriceString) \(isYearly ? "per year" : "per month"). Renews automatically unless cancelled at least 24 hours before renewal."
        }

        return "\(package.localizedPriceString) \(isYearly ? "per year" : "per month"). Renews automatically unless cancelled at least 24 hours before renewal."
    }
}
