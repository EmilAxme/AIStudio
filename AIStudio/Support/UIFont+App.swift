import UIKit

/// App typography — Inter (the design font), with a graceful system fallback.
enum AppFont {
    static func font(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "Inter-Bold"
        case .semibold:             name = "Inter-SemiBold"
        case .medium:               name = "Inter-Medium"
        default:                    name = "Inter-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    static func regular(_ size: CGFloat) -> UIFont { font(size, .regular) }
    static func medium(_ size: CGFloat) -> UIFont { font(size, .medium) }
    static func semibold(_ size: CGFloat) -> UIFont { font(size, .semibold) }
    static func bold(_ size: CGFloat) -> UIFont { font(size, .bold) }
}

extension UIFont {
    // Compatibility shim so existing call sites keep working — now backed by Inter.
    enum App {
        static func display(_ size: CGFloat) -> UIFont { AppFont.bold(size) }
        static func title(_ size: CGFloat = 24) -> UIFont { AppFont.semibold(size) }
        static func body(_ size: CGFloat = 17) -> UIFont { AppFont.regular(size) }
        static func medium(_ size: CGFloat = 17) -> UIFont { AppFont.medium(size) }
        static func bold(_ size: CGFloat = 17) -> UIFont { AppFont.bold(size) }
    }
}
