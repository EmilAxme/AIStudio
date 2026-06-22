import UIKit

/// App typography - Inter (the design font), with a graceful system fallback.
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
