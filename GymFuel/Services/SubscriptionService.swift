import Foundation
import RevenueCat

struct SubscriptionPurchaseResult {
    let customerInfo: CustomerInfo
    let userCancelled: Bool
}

final class SubscriptionService: NSObject, @unchecked Sendable {
    static let shared = SubscriptionService()

    private var isConfigured = false

    private override init() {}

    func configureIfNeeded() {
        guard !isConfigured else { return }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: SubscriptionConfig.revenueCatAPIKey)
        isConfigured = true
    }

    func logIn(userId: String) async throws -> CustomerInfo {
        configureIfNeeded()
        let result = try await Purchases.shared.logIn(userId)
        return result.customerInfo
    }

    func logOut() async throws -> CustomerInfo {
        configureIfNeeded()
        return try await Purchases.shared.logOut()
    }

    func customerInfo() async throws -> CustomerInfo {
        configureIfNeeded()
        return try await Purchases.shared.customerInfo()
    }

    func restorePurchases() async throws -> CustomerInfo {
        configureIfNeeded()
        return try await Purchases.shared.restorePurchases()
    }

    func paywallPackages() async throws -> [Package] {
        configureIfNeeded()

        let offerings = try await Purchases.shared.offerings()
        let offering = offerings.offering(identifier: SubscriptionConfig.offeringIdentifier) ?? offerings.current
        guard let offering else { return [] }

        let configuredPackages = [
            offering.package(identifier: SubscriptionConfig.proYearlyPackageIdentifier),
            offering.package(identifier: SubscriptionConfig.proMonthlyPackageIdentifier),
        ].compactMap { $0 }

        if !configuredPackages.isEmpty {
            return configuredPackages
        }

        return offering.availablePackages
            .filter {
                $0.storeProduct.productIdentifier == SubscriptionConfig.proYearlyProductIdentifier ||
                $0.storeProduct.productIdentifier == SubscriptionConfig.proMonthlyProductIdentifier
            }
            .sorted { first, second in
                first.storeProduct.productIdentifier == SubscriptionConfig.proYearlyProductIdentifier &&
                second.storeProduct.productIdentifier != SubscriptionConfig.proYearlyProductIdentifier
            }
    }

    func trialEligibilityByProductIdentifier(for packages: [Package]) async -> [String: IntroEligibilityStatus] {
        configureIfNeeded()

        let productIdentifiers = packages.map(\.storeProduct.productIdentifier)
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(
            productIdentifiers: productIdentifiers
        )

        return eligibility.reduce(into: [:]) { result, pair in
            result[pair.key] = pair.value.status
        }
    }

    func purchase(package: Package) async throws -> SubscriptionPurchaseResult {
        configureIfNeeded()

        let result = try await Purchases.shared.purchase(package: package)
        return SubscriptionPurchaseResult(
            customerInfo: result.customerInfo,
            userCancelled: result.userCancelled
        )
    }

    func plan(from customerInfo: CustomerInfo) -> SubscriptionPlan {
        guard
            let entitlement = customerInfo.entitlements[SubscriptionConfig.entitlementIdentifier],
            entitlement.isActive
        else {
            return .free
        }

        switch entitlement.productIdentifier {
        case SubscriptionConfig.proMonthlyProductIdentifier,
             SubscriptionConfig.proYearlyProductIdentifier:
            return .pro
        default:
            return .pro
        }
    }
}
