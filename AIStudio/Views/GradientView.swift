import UIKit

class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    init(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1),
        locations: [NSNumber]? = nil,
        type: CAGradientLayerType = .axial
    ) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
        gradientLayer.type = type
    }

    required init?(coder: NSCoder) { nil }

    func update(colors: [UIColor]) {
        gradientLayer.colors = colors.map(\.cgColor)
    }
}

// MARK: - GlowView
final class GlowView: GradientView {
    init(tint: UIColor = UIColor(hex: 0x4B2E59), intensity: CGFloat = 0.55) {
        super.init(
            colors: [tint.withAlphaComponent(intensity),
                     tint.withAlphaComponent(intensity * 0.4),
                     AppColor.background.withAlphaComponent(0)],
            startPoint: CGPoint(x: 0.5, y: 0.32),
            endPoint: CGPoint(x: 1.05, y: 1.0),
            locations: [0, 0.55, 1],
            type: .radial
        )
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { nil }
}

// MARK: - GradientBorderView
final class GradientBorderView: UIView {
    private let gradient: GradientView
    private let contentView = UIView()
    private let borderWidth: CGFloat

    init(
        cornerRadius: CGFloat,
        borderWidth: CGFloat = 1,
        fillColor: UIColor = AppColor.field,
        borderColors: [UIColor] = AppColor.inputGradient
    ) {
        self.borderWidth = borderWidth
        gradient = GradientView(colors: borderColors)
        super.init(frame: .zero)
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
        gradient.isUserInteractionEnabled = false
        contentView.backgroundColor = fillColor
        contentView.layer.cornerRadius = cornerRadius - borderWidth
        addSubviews(gradient, contentView)
        gradient.pinToEdges(of: self)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: borderWidth),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -borderWidth),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: borderWidth),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -borderWidth)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func addContent(_ view: UIView) {
        contentView.addSubview(view)
    }
}
