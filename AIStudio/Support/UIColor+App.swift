import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - AppColor
enum AppColor {
    static let background = UIColor(hex: 0x0B070E)
    static let surface = UIColor(hex: 0x1A141B)
    static let surfaceRaised = UIColor(hex: 0x211B22)
    static let bubble = UIColor(hex: 0x151017)
    static let field = UIColor(hex: 0x100B13)
    static let disabled = UIColor(hex: 0x1B171D)

    static let white = UIColor.white
    static let secondaryText = UIColor(hex: 0x8E8A93)
    static let mutedText = UIColor(hex: 0x6E6973)

    static let pink = UIColor(hex: 0xEB5B92)
    static let separator = UIColor.white.withAlphaComponent(0.30)
    static let hairline = UIColor.white.withAlphaComponent(0.10)
    static let inputGradient = [UIColor(hex: 0x98C6F7), UIColor(hex: 0xEB5B92)]
}
