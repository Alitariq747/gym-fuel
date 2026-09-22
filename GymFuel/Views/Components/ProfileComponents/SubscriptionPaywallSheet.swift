import RevenueCat
import SwiftUI

struct SubscriptionPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel

    private let privacyURL = URL(string: "https://ahmadtariq.co/apps/lifteats/privacy")!
    private let termsURL = URL(string: "https://ahmadtariq.co/apps/lifteats/terms")!

    private var selectedPackage: Package? {
        subscriptionViewModel.selectedPackage
    }

    private var features: [(symbol: String, title: String, detail: String)] {
        [
            ("text.viewfinder", "Describe or photograph a meal", "Get an estimate for food you actually eat."),
            ("list.bullet.rectangle", "See what was assumed", "Review portions, ingredients and preparation behind the numbers."),
            ("slider.horizontal.3", "Correct your version", "Adjust item amounts and see how the meal total changes."),
            ("bookmark", "Save it for next time", "Reuse a corrected meal with its breakdown and assumptions."),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    featureList
                    purchaseSection
                    restoreAndLegalSection
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.bottom, 24)
            }
        }
        .circaPaper()
        .task {
            await subscriptionViewModel.loadPaywallPackages()
        }
    }

    private var headerBar: some View {
        HStack {
            CircaSectionLabel("Circa Pro")
            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.circaInk)
                    .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    .background(Color.circaCard, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close paywall")
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.top, 12)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("Understand the food you actually eat.")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)

            Text("See what went into an estimate, correct what differs, and save your version.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(features, id: \.title) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.symbol)
                        .font(.circaRow)
                        .foregroundStyle(Color.circaAccent)
                        .frame(width: 42, height: 42)
                        .background(Color.circaWell, in: RoundedRectangle(cornerRadius: Circa.Radius.thumb))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.circaRow.weight(.semibold))
                            .foregroundStyle(Color.circaInk)

                        Text(feature.detail)
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                if feature.title != features.last?.title {
                    CircaHairline(weight: .inCard).padding(.horizontal, 12)
                }
            }
        }
        .background(ProfileCardBackground())
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
                .font(.circaRow)
                .foregroundStyle(Color.circaInk)
                .frame(minHeight: Circa.minHitTarget)
            }
            .buttonStyle(.plain)
            .disabled(subscriptionViewModel.isPurchasing || subscriptionViewModel.isRestoring)

            VStack(spacing: 4) {
                Link("Privacy Policy", destination: privacyURL)
                Link("Terms of Service", destination: termsURL)
            }
            .font(.circaCaption)
            .foregroundStyle(Color.circaInk2)
        }
        .frame(maxWidth: .infinity)
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let errorMessage = subscriptionViewModel.errorMessage {
                Text(errorMessage)
                    .font(.circaCaption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.circaDanger)
                    .padding(.horizontal, 12)
            }

            CircaCard {
                VStack(spacing: 12) {
                    CircaSectionLabel("Choose your plan")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    packageOptions
                    continueButton
                    renewalFooter
                }
            }
        }
    }

    @ViewBuilder
    private var packageOptions: some View {
        if subscriptionViewModel.isLoadingPackages {
            ProgressView()
                .padding(.vertical, 28)
        } else if subscriptionViewModel.paywallPackages.isEmpty {
            VStack(spacing: 12) {
                Text("Subscription options are unavailable. Please try again.")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
                    .multilineTextAlignment(.center)

                Button {
                    Task {
                        await subscriptionViewModel.loadPaywallPackages()
                    }
                } label: {
                    Text("Retry")
                        .font(.circaRow)
                        .foregroundStyle(Color.circaAccent)
                        .frame(minHeight: Circa.minHitTarget)
                }
                .buttonStyle(.plain)
            }
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
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))

        return Button {
            guard subscriptionViewModel.isPurchasing == false,
                  subscriptionViewModel.isRestoring == false else { return }
            subscriptionViewModel.selectPackage(package)
        } label: {
            layout {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.circaAccent : Color.circaInk3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Pro Yearly" : "Pro Monthly")
                            .font(.circaRow.weight(.semibold))
                            .foregroundStyle(Color.circaInk)

                        if isYearly {
                            Text("Best value")
                                .font(.circaMono)
                                .foregroundStyle(Color.circaAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.circaSunken, in: Capsule())
                        }
                    }

                    Text(packageSubtitle(for: package))
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                }

                if !dynamicTypeSize.isAccessibilitySize { Spacer() }

                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
                    Text(package.localizedPriceString)
                        .font(.circaMonoValue)
                        .foregroundStyle(Color.circaInk)

                    Text(isYearly ? "/ year" : "/ month")
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk2)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                    .fill(isSelected ? Color.circaSunken : Color.circaCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                    .stroke(isSelected ? Color.circaAccent : Color.circaCardBorder, lineWidth: isSelected ? 1.5 : 1)
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
            Group {
                if subscriptionViewModel.isPurchasing {
                    ProgressView()
                } else {
                    Text(continueButtonTitle)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.circa(.primary, height: 52))
        .disabled(
            selectedPackage == nil ||
            subscriptionViewModel.isLoadingPackages ||
            subscriptionViewModel.isPurchasing ||
            subscriptionViewModel.isRestoring
        )
        .opacity(selectedPackage == nil ? 0.55 : 1)
    }

    private var continueButtonTitle: String {
        guard let selectedPackage,
              let trialLength = trialLengthText(for: selectedPackage)
        else { return "Continue" }

        return "Start \(trialLength) free trial"
    }

    private var renewalFooter: some View {
        Text(selectedPackage.map(footerText(for:)) ?? "Subscription renews automatically unless cancelled at least 24 hours before renewal.")
            .font(.circaMono)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.circaInk2)
            .padding(.horizontal, 8)
    }

    private func trialLengthText(for package: Package) -> String? {
        guard subscriptionViewModel.isEligibleForTrial(package),
              let discount = package.storeProduct.introductoryDiscount,
              discount.paymentMode == .freeTrial
        else { return nil }

        let period = discount.subscriptionPeriod
        let count = period.value * discount.numberOfPeriods

        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        }

        return "\(count)-\(unit)"
    }

    private func packageSubtitle(for package: Package) -> String {
        if let trialLength = trialLengthText(for: package) {
            return "\(trialLength) free trial available"
        }

        return billingText(for: package)
    }

    private func billingText(for package: Package) -> String {
        let isYearly = package.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier
        return "\(package.localizedPriceString) \(isYearly ? "per year" : "per month")"
    }

    private func footerText(for package: Package) -> String {
        let isYearly = package.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier

        if let trialLength = trialLengthText(for: package) {
            return "\(trialLength) free trial, then \(package.localizedPriceString) \(isYearly ? "per year" : "per month"). Renews automatically unless cancelled at least 24 hours before renewal. Cancel anytime in your Apple account settings."
        }

        return "\(package.localizedPriceString) \(isYearly ? "per year" : "per month"). Renews automatically unless cancelled at least 24 hours before renewal. Cancel anytime in your Apple account settings."
    }
}

#Preview("SE") {
    SubscriptionPaywallSheet()
        .environmentObject(SubscriptionViewModel())
}
