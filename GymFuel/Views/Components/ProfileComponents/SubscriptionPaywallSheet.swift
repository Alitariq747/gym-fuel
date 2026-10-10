import RevenueCat
import SwiftUI

struct SubscriptionPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    @State private var page: PaywallPage = .features

    private let context: PaywallContext?

    init(context: PaywallContext? = nil) {
        self.context = context
    }

    private var selectedPackage: Package? {
        subscriptionViewModel.selectedPackage
    }

    private var hasTrial: Bool {
        selectedPackage.flatMap(subscriptionViewModel.trialTimeline(for:)) != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            ScrollView {
                VStack(spacing: 20) {
                    pageContent
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.bottom, 24)
            }
            .id(page)

            if page == .plans {
                purchaseBar
            } else {
                continueBar
            }
        }
        .circaPaper()
        .task {
            await subscriptionViewModel.loadPaywallPackages()
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case .features:
            PaywallFeaturesPage(context: context)
        case .trial:
            if let selectedPackage, let timeline = subscriptionViewModel.trialTimeline(for: selectedPackage) {
                PaywallTrialPage(
                    timeline: timeline,
                    billing: billingText(for: selectedPackage),
                    planName: selectedPackage.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier ? "yearly" : "monthly"
                )
            }
        case .plans:
            PaywallPageHeader(label: "Circa Pro", title: "Choose your plan")
            purchaseSection
        }
    }

    private var continueBar: some View {
        Button {
            show(page.next(hasTrial: hasTrial) ?? .plans)
        } label: {
            Text("Continue")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.circa(.primary, height: 52))
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.bottom, 12)
    }

    private func show(_ next: PaywallPage) {
        withAnimation(.easeInOut(duration: 0.2)) {
            page = next
        }
    }

    private var headerBar: some View {
        HStack {
            if let previous = page.previous(hasTrial: hasTrial) {
                Button {
                    show(previous)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.circaRow.weight(.semibold))
                        .foregroundStyle(Color.circaInk)
                        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
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
                Link("Privacy Policy", destination: AppConfig.privacyPolicyURL)
                Link("Terms of Service", destination: AppConfig.termsURL)
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

            packageOptions
        }
    }

    private var purchaseBar: some View {
        VStack(spacing: 12) {
            if hasTrial {
                Text("Nothing due today")
                    .font(.circaBody.weight(.semibold))
                    .foregroundStyle(Color.circaAccent)
            }
            continueButton
            renewalFooter
            restoreAndLegalSection
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.bottom, 12)
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
                Image(systemName: isSelected ? "checkmark.circle" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.circaInk : Color.circaInk3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Yearly" : "Monthly")
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
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
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
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                    .fill(Color.circaCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                    .stroke(isSelected ? Color.circaInk : Color.circaCardBorder, lineWidth: isSelected ? 1.5 : 1)
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
              let trialLength = subscriptionViewModel.trialTimeline(for: selectedPackage)?.lengthText
        else { return "Subscribe" }

        return "Start \(trialLength) free trial"
    }

    private var renewalFooter: some View {
        Text(selectedPackage.map(footerText(for:)) ?? "Subscription renews automatically unless cancelled at least 24 hours before renewal.")
            .font(.circaMono)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.circaInk2)
            .padding(.horizontal, 8)
    }

    private func packageSubtitle(for package: Package) -> String {
        if let trialLength = subscriptionViewModel.trialTimeline(for: package)?.lengthText {
            return "\(trialLength) free trial"
        }

        return billingText(for: package)
    }

    private func billingText(for package: Package) -> String {
        let isYearly = package.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier
        return "\(package.localizedPriceString) \(isYearly ? "per year" : "per month")"
    }

    private func footerText(for package: Package) -> String {
        let isYearly = package.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier

        if let trialLength = subscriptionViewModel.trialTimeline(for: package)?.lengthText {
            return "\(trialLength) free trial, then \(package.localizedPriceString) \(isYearly ? "per year" : "per month"). Renews automatically unless cancelled at least 24 hours before renewal. Cancel anytime in your Apple account settings."
        }

        return "\(package.localizedPriceString) \(isYearly ? "per year" : "per month"). Renews automatically unless cancelled at least 24 hours before renewal. Cancel anytime in your Apple account settings."
    }
}

#Preview("SE") {
    SubscriptionPaywallSheet()
        .environmentObject(SubscriptionViewModel())
}
