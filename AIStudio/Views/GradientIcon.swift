import UIKit

final class GradientIconView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
    private let maskLayer = CALayer()
    private let iconImage: UIImage

    init(
        image: UIImage,
        colors: [UIColor] = AppColor.inputGradient,
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        iconImage = image
        super.init(frame: .zero)
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        maskLayer.contents = iconImage.cgImage
        maskLayer.contentsGravity = .resizeAspect
        layer.mask = maskLayer
    }

    convenience init(
        imageName: String,
        colors: [UIColor] = AppColor.inputGradient,
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        let img = UIImage(named: imageName) ?? UIImage()
        self.init(image: img, colors: colors, startPoint: startPoint, endPoint: endPoint)
    }

    convenience init(
        symbol: String,
        pointSize: CGFloat,
        weight: UIImage.SymbolWeight = .medium,
        colors: [UIColor] = AppColor.inputGradient,
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        let img = (UIImage(systemName: symbol, withConfiguration: config) ?? UIImage())
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        self.init(image: img, colors: colors, startPoint: startPoint, endPoint: endPoint)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = bounds
    }

    override var intrinsicContentSize: CGSize { iconImage.size }
}

// MARK: - GradientLabel
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

// MARK: - SparkleLogoView
final class SparkleLogoView: UIView {
    init() {
        super.init(frame: .zero)
        let sparkle = UIImageView(image: UIImage(named: "icSparkleCluster"))
        sparkle.contentMode = .scaleAspectFit
        sparkle.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sparkle)
        NSLayoutConstraint.activate([
            sparkle.centerXAnchor.constraint(equalTo: centerXAnchor),
            sparkle.centerYAnchor.constraint(equalTo: centerYAnchor),
            sparkle.widthAnchor.constraint(equalToConstant: 56),
            sparkle.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize { CGSize(width: 58, height: 56) }
}
