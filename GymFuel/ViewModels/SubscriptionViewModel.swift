import Foundation
import RevenueCat

enum SubscriptionPlan: Equatable {
    case free
    case pro

    var displayName: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        }
    }
}

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published private(set) var currentPlan: SubscriptionPlan = .free
    @Published private(set) var status: SubscriptionStatus = .free
    @Published private(set) var paywallPackages: [Package] = []
    @Published private(set) var selectedPackageIdentifier: String?
    @Published private(set) var introEligibilityByProductIdentifier: [String: IntroEligibilityStatus] = [:]
    @Published private(set) var isLoadingPackages = false
    @Published private(set) var isSyncingStatus = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published private(set) var errorMessage: String?

    private let service: SubscriptionService
    private let backendSubscriptionService: BackendSubscriptionService
    private var syncedUserId: String?

    var hasProAccess: Bool {
        status.hasProAccess
    }

    var selectedPackage: Package? {
        paywallPackages.first { $0.identifier == selectedPackageIdentifier } ?? paywallPackages.first
    }

    init(
        service: SubscriptionService = .shared,
        backendSubscriptionService: BackendSubscriptionService = .shared
    ) {
        self.service = service
        self.backendSubscriptionService = backendSubscriptionService
    }

    func syncUser(userId: String?) async {
        if syncedUserId == userId {
            if userId != nil {
                await refreshCustomerInfo()
            }
            return
        }

        isSyncingStatus = true
        errorMessage = nil

        do {
            if let userId {
                let customerInfo = try await service.logIn(userId: userId)
                syncedUserId = userId
                applyCustomerInfo(customerInfo)
                _ = await syncBackendSubscriptionIfNeeded()
            } else {
                if syncedUserId != nil {
                    _ = try await service.logOut()
                }
                syncedUserId = nil
                applyFreeStatus()
            }
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't sync your subscription status."
            )
        }

        isSyncingStatus = false
    }

    func refreshCustomerInfo(showBackendSyncWarning: Bool = false) async {
        isSyncingStatus = true
        errorMessage = nil

        do {
            let customerInfo = try await service.customerInfo()
            applyCustomerInfo(customerInfo)
            let didSyncBackend = await syncBackendSubscriptionIfNeeded()

            if showBackendSyncWarning && status.hasProAccess && !didSyncBackend {
                errorMessage = "Your subscription is active, but we couldn't sync AI access yet. Please try Refresh or Restore."
            }
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't refresh your subscription status."
            )
        }

        isSyncingStatus = false
    }

    func loadPaywallPackages() async {
        errorMessage = nil
        guard paywallPackages.isEmpty else { return }

        isLoadingPackages = true

        do {
            let packages = try await service.paywallPackages()
            paywallPackages = packages
            selectedPackageIdentifier = packages.first?.identifier
            introEligibilityByProductIdentifier = await service.trialEligibilityByProductIdentifier(for: packages)
        } catch PaywallPackagesError.offeringUnavailable {
            errorMessage = "Subscription options aren't available right now. Please try again later."
            FirebaseTelemetryService.recordNonFatal(
                PaywallPackagesError.offeringUnavailable,
                reason: "paywall_packages_load_failed",
                metadata: [
                    "case": "offeringUnavailable",
                ]
            )
        } catch PaywallPackagesError.packagesUnavailable(let offeringIdentifier, let availableProductIdentifiers) {
            errorMessage = "We couldn't find the subscription options for this offering. Please try again later."
            #if DEBUG
            print("paywallPackages: no packages matched in offering '\(offeringIdentifier)'. Available product identifiers: \(availableProductIdentifiers)")
            #endif
            FirebaseTelemetryService.recordNonFatal(
                PaywallPackagesError.packagesUnavailable(
                    offeringIdentifier: offeringIdentifier,
                    availableProductIdentifiers: availableProductIdentifiers
                ),
                reason: "paywall_packages_load_failed",
                metadata: [
                    "case": "packagesUnavailable",
                    "offering_identifier": offeringIdentifier,
                    "available_product_identifiers": availableProductIdentifiers.joined(separator: ", "),
                ]
            )
        } catch PaywallPackagesError.timedOut {
            errorMessage = "Loading subscription options is taking longer than expected. Please check your connection and try again."
            FirebaseTelemetryService.recordNonFatal(
                PaywallPackagesError.timedOut,
                reason: "paywall_packages_load_failed",
                metadata: [
                    "case": "timedOut",
                ]
            )
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load subscription options. Please try again."
            )
        }

        isLoadingPackages = false
    }

    func selectPackage(_ package: Package) {
        selectedPackageIdentifier = package.identifier
    }

    func isEligibleForTrial(_ package: Package) -> Bool {
        guard package.storeProduct.introductoryDiscount != nil else { return false }

        let productIdentifier = package.storeProduct.productIdentifier
        return introEligibilityByProductIdentifier[productIdentifier] == .eligible
    }

    func purchaseSelectedPackage() async -> Bool {
        guard let selectedPackage else {
            errorMessage = "Please choose a subscription option."
            return false
        }

        return await purchase(package: selectedPackage)
    }

    func purchase(package: Package) async -> Bool {
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await service.purchase(package: package)

            if result.userCancelled {
                isPurchasing = false
                return false
            }

            let purchaseStatus = service.status(from: result.customerInfo)
            guard purchaseStatus.hasProAccess else {
                errorMessage = "Purchase completed, but Pro access was not activated. Please try Restore Subscription."
                isPurchasing = false
                return false
            }

            applyStatus(purchaseStatus)

            let didSyncBackend = await syncBackendSubscriptionIfNeeded()
            if !didSyncBackend {
                errorMessage = "Your subscription is active, but we couldn't sync AI access yet. Please try Refresh or Restore."
            }

            isPurchasing = false
            return true
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "Purchase completed, but we couldn't activate access yet. Please try Restore Subscription."
            )
            isPurchasing = false
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isRestoring = true
        errorMessage = nil

        do {
            let customerInfo = try await service.restorePurchases()
            let restoredStatus = service.status(from: customerInfo)

            guard restoredStatus.hasProAccess else {
                applyFreeStatus()
                errorMessage = "No active LiftEats Pro subscription was found for this Apple ID."
                isRestoring = false
                return false
            }

            applyStatus(restoredStatus)

            let didSyncBackend = await syncBackendSubscriptionIfNeeded()
            if !didSyncBackend {
                errorMessage = "Your subscription is active, but we couldn't sync AI access yet. Please try Refresh or Restore."
            }

            isRestoring = false
            return true
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't restore your subscription. Please try again."
            )
            isRestoring = false
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func syncBackendSubscriptionIfNeeded() async -> Bool {
        guard status.hasProAccess else { return true }

        do {
            try await backendSubscriptionService.syncSubscription()
            return true
        } catch {
            return false
        }
    }

    private func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        applyStatus(service.status(from: customerInfo))
    }

    private func applyStatus(_ newStatus: SubscriptionStatus) {
        status = newStatus
        currentPlan = newStatus.hasProAccess ? .pro : .free
    }

    private func applyFreeStatus() {
        status = SubscriptionStatus(
            state: .free,
            productKind: .unknown,
            productIdentifier: nil,
            expirationDate: nil,
            willRenew: false
        )
        currentPlan = .free
    }
}
