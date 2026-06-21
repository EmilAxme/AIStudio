import UIKit

/// An SF Symbol (or any template image) filled with a gradient by masking.
final class GradientIconView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
    private let maskLayer = CALayer()
    private let iconImage: UIImage

    init(
        symbol: String,
        pointSize: CGFloat,
        weight: UIImage.SymbolWeight = .medium,
        colors: [UIColor] = AppColor.inputGradient,
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        iconImage = (UIImage(systemName: symbol, withConfiguration: config) ?? UIImage())
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        super.init(frame: .zero)
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        maskLayer.contents = iconImage.cgImage
        maskLayer.contentsGravity = .resizeAspect
        layer.mask = maskLayer
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = bounds
    }

    override var intrinsicContentSize: CGSize { iconImage.size }
}

/// A single-line label whose glyphs are filled with a horizontal gradient.
final class GradientLabel: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
    private let label = UILabel()

    init(text: String, font: UIFont, colors: [UIColor] = AppColor.inputGradient) {
        super.init(frame: .zero)
        label.text = text
        label.font = font
        label.numberOfLines = 1
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.mask = label.layer
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }

    override var intrinsicContentSize: CGSize { label.intrinsicContentSize }
}

/// Multi-colour sparkle cluster used as the Home hero logo.
final class SparkleLogoView: UIView {
    init() {
        super.init(frame: .zero)
        let big = GradientIconView(
            symbol: "sparkles",
            pointSize: 44,
            weight: .medium,
            startPoint: CGPoint(x: 0.1, y: 0.2),
            endPoint: CGPoint(x: 0.9, y: 0.9)
        )
        let accent = GradientIconView(
            symbol: "sparkle",
            pointSize: 16,
            weight: .semibold,
            colors: [AppColor.pink, UIColor(hex: 0xF2A6C6)]
        )
        addSubviews(big, accent)
        NSLayoutConstraint.activate([
            big.centerXAnchor.constraint(equalTo: centerXAnchor),
            big.centerYAnchor.constraint(equalTo: centerYAnchor),
            accent.trailingAnchor.constraint(equalTo: big.trailingAnchor, constant: 6),
            accent.topAnchor.constraint(equalTo: big.topAnchor, constant: -2)
        ])
    }

    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize { CGSize(width: 58, height: 52) }
}
