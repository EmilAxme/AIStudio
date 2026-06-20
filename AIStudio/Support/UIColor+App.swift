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

enum AppColor {
    static let background = UIColor(hex: 0x09050E)
    static let surface = UIColor(hex: 0x141019)
    static let surfaceRaised = UIColor(hex: 0x1D1720)
    static let field = UIColor(hex: 0x18121A)
    static let white = UIColor.white
    static let secondaryText = UIColor(hex: 0xA39DA8)
    static let mutedText = UIColor(hex: 0x67616C)
    static let blue = UIColor(hex: 0x9CCBFF)
    static let lavender = UIColor(hex: 0xBCAEEB)
    static let pink = UIColor(hex: 0xEC5597)
    static let separator = UIColor(hex: 0x4D4652)
    static let inputGradient = [UIColor(hex: 0x9CCBFF), UIColor(hex: 0xBDABE7), UIColor(hex: 0xEC5597)]
}
