import UIKit

extension UIFont {
    enum App {
        static func display(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
        static func title(_ size: CGFloat = 24) -> UIFont { .systemFont(ofSize: size, weight: .semibold) }
        static func body(_ size: CGFloat = 17) -> UIFont { .systemFont(ofSize: size, weight: .regular) }
        static func medium(_ size: CGFloat = 17) -> UIFont { .systemFont(ofSize: size, weight: .medium) }
        static func bold(_ size: CGFloat = 17) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    }
}
