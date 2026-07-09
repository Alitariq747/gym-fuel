import Foundation
import RevenueCat

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published private(set) var currentPlan: SubscriptionPlan = .free
    @Published private(set) var paywallPackages: [Package] = []
    @Published private(set) var introEligibilityByProductIdentifier: [String: IntroEligibilityStatus] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var errorMessage: String?

    private let service: SubscriptionService
    private let backendSubscriptionService: BackendSubscriptionService
    private var syncedUserId: String?

    var hasPaidEntitlement: Bool {
        currentPlan != .free
    }

    init(
        service: SubscriptionService = .shared,
        backendSubscriptionService: BackendSubscriptionService = .shared
    ) {
        self.service = service
        self.backendSubscriptionService = backendSubscriptionService
    }

    func configure() {
        service.configureIfNeeded()
    }

    func syncUser(userId: String?) async {
        if syncedUserId == nil, userId == nil {
            currentPlan = .free
            return
        }

        guard syncedUserId != userId else {
            if userId != nil {
                await refreshCustomerInfo()
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if let userId {
                let customerInfo = try await service.logIn(userId: userId)
                syncedUserId = userId
                update(from: customerInfo)
            } else {
                if syncedUserId != nil {
                    let customerInfo = try await service.logOut()
                    update(from: customerInfo)
                }
                syncedUserId = nil
                currentPlan = .free
            }
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load your subscription status."
            )
        }

        isLoading = false
    }

    func refreshCustomerInfo() async {
        isLoading = true
        errorMessage = nil

        do {
            let customerInfo = try await service.customerInfo()
            update(from: customerInfo)
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't refresh your subscription status."
            )
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            let customerInfo = try await service.restorePurchases()
            if service.plan(from: customerInfo) == .pro {
                try await backendSubscriptionService.syncSubscription()
            }
            update(from: customerInfo)
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "Subscription restored, but we couldn't sync access yet. Please try Restore again."
            )
        }

        isLoading = false
    }

    func loadPaywallPackages() async {
        isLoading = true
        errorMessage = nil

        do {
            let packages = try await service.paywallPackages()
            paywallPackages = packages
            introEligibilityByProductIdentifier = await service.trialEligibilityByProductIdentifier(for: packages)
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load subscription options. Please try again."
            )
        }

        isLoading = false
    }

    func purchase(package: Package) async -> Bool {
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await service.purchase(package: package)
            update(from: result.customerInfo)
            isPurchasing = false
            return !result.userCancelled && service.plan(from: result.customerInfo) == .pro
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't complete the purchase. Please try again."
            )
            isPurchasing = false
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func update(from customerInfo: CustomerInfo) {
        currentPlan = service.plan(from: customerInfo)
    }
}
