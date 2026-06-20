import Foundation

enum SubscriptionPlan: CaseIterable {
    case yearly
    case monthly

    var title: String {
        switch self {
        case .yearly: return "Year $1.27 / week"
        case .monthly: return "Month $1.99 / week"
        }
    }

    var detail: String {
        switch self {
        case .yearly: return "$ 69.99"
        case .monthly: return "$ 7.99"
        }
    }
}
