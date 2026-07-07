import Foundation

enum SubscriptionConfig {
    static let revenueCatAPIKey = "appl_eVCJtAkJfJAskxlNlYrFqFeULej"
    static let entitlementIdentifier = "ai_scans"
    static let offeringIdentifier = "default"

    static let proMonthlyProductIdentifier = "lifteats_pro_monthly"
    static let proYearlyProductIdentifier = "lifteats_pro_yearly"

    static let proMonthlyPackageIdentifier = "pro_monthly"
    static let proYearlyPackageIdentifier = "pro_yearly"
}

enum SubscriptionPlan: Equatable {
    case free
    case pro

    var displayName: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        }
    }

    var profileDescription: String {
        switch self {
        case .free: "Upgrade to LiftEats Pro"
        case .pro: "LiftEats Pro is active"
        }
    }
}
