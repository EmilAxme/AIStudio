import UIKit

final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    init(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1)) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }

    required init?(coder: NSCoder) { nil }

    func update(colors: [UIColor]) {
        gradientLayer.colors = colors.map(\.cgColor)
    }
}

final class GradientBorderView: UIView {
    private let gradient = GradientView(colors: AppColor.inputGradient)
    private let contentView = UIView()
    private let borderWidth: CGFloat

    init(cornerRadius: CGFloat, borderWidth: CGFloat = 1.2, fillColor: UIColor = AppColor.field) {
        self.borderWidth = borderWidth
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
