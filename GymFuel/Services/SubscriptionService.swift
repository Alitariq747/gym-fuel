import Foundation
import RevenueCat

struct SubscriptionPurchaseResult {
    let customerInfo: CustomerInfo
    let userCancelled: Bool
}

enum SubscriptionProductKind: Equatable {
    case monthly
    case yearly
    case unknown
}

enum SubscriptionStatusState: Equatable {
    case free
    case trial
    case active
}

struct SubscriptionStatus: Equatable {
    let state: SubscriptionStatusState
    let productKind: SubscriptionProductKind
    let productIdentifier: String?
    let expirationDate: Date?
    let willRenew: Bool

    static let free = SubscriptionStatus(
        state: .free,
        productKind: .unknown,
        productIdentifier: nil,
        expirationDate: nil,
        willRenew: false
    )

    var hasProAccess: Bool {
        state == .trial || state == .active
    }

    var isTrial: Bool {
        state == .trial
    }

    var isCancelledButActive: Bool {
        hasProAccess && !willRenew && expirationDate != nil
    }
}

final class SubscriptionService: NSObject, @unchecked Sendable {
    static let shared = SubscriptionService()

    private var isConfigured = false

    private override init() {
        super.init()
    }

    func configureIfNeeded() {
        guard !isConfigured else { return }

        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: RevenueCatConfig.publicSDKKey)

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

    func paywallPackages() async throws -> [Package] {
        configureIfNeeded()

        let offerings = try await Purchases.shared.offerings()
        let offering = offerings.offering(identifier: RevenueCatConfig.offeringIdentifier) ?? offerings.current

        guard let offering else {
            return []
        }

        let configuredPackages = [
            offering.package(identifier: RevenueCatConfig.proYearlyPackageIdentifier),
            offering.package(identifier: RevenueCatConfig.proMonthlyPackageIdentifier),
        ].compactMap { $0 }

        if !configuredPackages.isEmpty {
            return configuredPackages
        }

        return offering.availablePackages.filter {
            $0.storeProduct.productIdentifier == RevenueCatConfig.proYearlyProductIdentifier ||
            $0.storeProduct.productIdentifier == RevenueCatConfig.proMonthlyProductIdentifier
        }
    }

    func trialEligibilityByProductIdentifier(for packages: [Package]) async -> [String: IntroEligibilityStatus] {
        configureIfNeeded()

        let productIdentifiers = packages.map(\.storeProduct.productIdentifier)
        guard !productIdentifiers.isEmpty else { return [:] }

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers)
        return eligibility.mapValues(\.status)
    }

    func purchase(package: Package) async throws -> SubscriptionPurchaseResult {
        configureIfNeeded()

        let result = try await Purchases.shared.purchase(package: package)
        return SubscriptionPurchaseResult(
            customerInfo: result.customerInfo,
            userCancelled: result.userCancelled
        )
    }

    func restorePurchases() async throws -> CustomerInfo {
        configureIfNeeded()
        return try await Purchases.shared.restorePurchases()
    }

    func status(from customerInfo: CustomerInfo) -> SubscriptionStatus {
        guard
            let entitlement = customerInfo.entitlements[RevenueCatConfig.entitlementIdentifier],
            entitlement.isActive
        else {
            return SubscriptionStatus(
                state: .free,
                productKind: .unknown,
                productIdentifier: nil,
                expirationDate: nil,
                willRenew: false
            )
        }

        return SubscriptionStatus(
            state: entitlement.periodType == .trial ? .trial : .active,
            productKind: productKind(for: entitlement.productIdentifier),
            productIdentifier: entitlement.productIdentifier,
            expirationDate: entitlement.expirationDate,
            willRenew: entitlement.willRenew
        )
    }

    func plan(from customerInfo: CustomerInfo) -> SubscriptionPlan {
        status(from: customerInfo).hasProAccess ? .pro : .free
    }

    private func productKind(for productIdentifier: String) -> SubscriptionProductKind {
        switch productIdentifier {
        case RevenueCatConfig.proMonthlyProductIdentifier:
            return .monthly
        case RevenueCatConfig.proYearlyProductIdentifier:
            return .yearly
        default:
            return .unknown
        }
    }
}
