import Foundation
import StoreKit
import ApphudSDK

/// Read-only premium gate used by feature screens for DI/testability.
protocol SubscriptionServicing: AnyObject {
    var isPremium: Bool { get }
}

/// Single source of truth for subscription state and purchases, backed by Apphud.
///
/// Posts `statusDidChange` (object: `Bool` isPremium) after a purchase/restore or
/// when Apphud reports an update, so gated screens unlock live - no relaunch.
final class SubscriptionService: NSObject, SubscriptionServicing {
    static let statusDidChange = Notification.Name("SubscriptionService.statusDidChange")

    var isPremium: Bool { Apphud.hasActiveSubscription() }

    // MARK: - Paywall

    /// Loads the configured paywall (`AppConfig.Apphud.paywallID`) via placements
    /// and marks it shown for Apphud analytics. Returns `nil` if it can't load.
    func loadPaywall() async -> ApphudPaywall? {
        let placements = await Apphud.placements()
        let paywalls = placements.compactMap { $0.paywall }
        let paywall = placements.first(where: { $0.identifier == AppConfig.Apphud.paywallID })?.paywall
            ?? paywalls.first(where: { $0.identifier == AppConfig.Apphud.paywallID })
            ?? paywalls.first
        if let paywall {
            await MainActor.run { Apphud.paywallShown(paywall) }
            #if DEBUG
            let ids = paywall.products.map { $0.productId }.joined(separator: ", ")
            NSLog("[Apphud] paywall '\(paywall.identifier)' products: [\(ids)]")
            #endif
        }
        return paywall
    }

    // MARK: - Purchase / Restore

    @MainActor
    func purchase(_ product: ApphudProduct) async -> Result<Bool, Error> {
        let result = await Apphud.purchase(product)
        broadcastStatus()
        if let error = result.error {
            return .failure(error)
        }
        return .success(isPremium)
    }

    @MainActor
    func restore() async -> Result<Bool, Error> {
        let error = await Apphud.restorePurchases()
        broadcastStatus()
        if let error {
            return .failure(error)
        }
        return .success(isPremium)
    }

    private func broadcastStatus() {
        let premium = isPremium
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.statusDidChange, object: premium)
        }
    }
}

// MARK: - ApphudDelegate (live subscription updates)

extension SubscriptionService: ApphudDelegate {
    func apphudSubscriptionsUpdated(_ subscriptions: [ApphudSubscription]) {
        broadcastStatus()
    }

    func apphudNonRenewingPurchasesUpdated(_ purchases: [ApphudNonRenewingPurchase]) {
        broadcastStatus()
    }
}

// MARK: - Price formatting (from StoreKit product, never hard-coded)

extension ApphudProduct {
    /// Localized price string, e.g. "$69.99" - from the StoreKit product.
    var displayPriceString: String? {
        guard let sk = skProduct else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = sk.priceLocale
        return formatter.string(from: sk.price)
    }

    /// Localized subscription period, e.g. "year" / "3 months".
    var displayPeriodString: String? {
        guard let period = skProduct?.subscriptionPeriod else { return nil }
        let unitName: String
        switch period.unit {
        case .day: unitName = "day"
        case .week: unitName = "week"
        case .month: unitName = "month"
        case .year: unitName = "year"
        @unknown default: unitName = ""
        }
        return period.numberOfUnits > 1 ? "\(period.numberOfUnits) \(unitName)s" : unitName
    }

    var hasFreeTrial: Bool {
        skProduct?.introductoryPrice?.paymentMode == .freeTrial
    }

    /// Per-week price (numeric) derived from the product's total price and period.
    var weeklyPriceValue: NSDecimalNumber? {
        guard let sk = skProduct, let period = sk.subscriptionPeriod else { return nil }
        let weeksPerUnit: Double
        switch period.unit {
        case .day: weeksPerUnit = 1.0 / 7.0
        case .week: weeksPerUnit = 1.0
        case .month: weeksPerUnit = 365.0 / 12.0 / 7.0
        case .year: weeksPerUnit = 52.0
        @unknown default: return nil
        }
        let totalWeeks = weeksPerUnit * Double(period.numberOfUnits)
        guard totalWeeks > 0 else { return nil }
        return sk.price.dividing(by: NSDecimalNumber(value: totalWeeks))
    }

    /// Localized per-week price, e.g. a $69.99/year product becomes "$1.35".
    var weeklyPriceString: String? {
        guard let weekly = weeklyPriceValue, let locale = skProduct?.priceLocale else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: weekly)
    }
}
