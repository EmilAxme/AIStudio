import UIKit
import ApphudSDK

final class PlanOptionView: UIControl {
    private let borderGradient = GradientView(colors: AppColor.inputGradient)
    private let inner = UIView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let badge = GradientView(colors: AppColor.inputGradient, startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
    private let badgeLabel = UILabel()
    private let borderWidth: CGFloat = 1.5

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    /// The product this row represents, set once the paywall loads.
    var product: ApphudProduct?

    init(showsSaveBadge: Bool, placeholderTitle: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 24
        clipsToBounds = true

        borderGradient.isUserInteractionEnabled = false
        inner.backgroundColor = AppColor.background
        inner.layer.cornerRadius = 24 - borderWidth
        inner.isUserInteractionEnabled = false

        titleLabel.text = placeholderTitle
        titleLabel.font = AppFont.font(16, .medium)
        titleLabel.textColor = .white
        detailLabel.text = " "
        detailLabel.font = AppFont.font(14, .regular)
        detailLabel.textColor = UIColor(hex: 0x606060)

        badge.layer.cornerRadius = 14
        badge.clipsToBounds = true
        badge.isUserInteractionEnabled = false
        badgeLabel.text = "SAVE 80%"
        badgeLabel.textColor = .white
        badgeLabel.font = AppFont.font(12, .semibold)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeLabel)

        addSubviews(borderGradient, inner)
        borderGradient.pinToEdges(of: self)
        inner.addSubviews(titleLabel, detailLabel, badge)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 66),
            inner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: borderWidth),
            inner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -borderWidth),
            inner.topAnchor.constraint(equalTo: topAnchor, constant: borderWidth),
            inner.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -borderWidth),

            titleLabel.leadingAnchor.constraint(equalTo: inner.leadingAnchor, constant: 24),
            titleLabel.topAnchor.constraint(equalTo: inner.topAnchor, constant: 14),
            detailLabel.leadingAnchor.constraint(equalTo: inner.leadingAnchor, constant: 24),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            badge.trailingAnchor.constraint(equalTo: inner.trailingAnchor, constant: -16),
            badge.centerYAnchor.constraint(equalTo: inner.centerYAnchor),
            badge.heightAnchor.constraint(equalToConstant: 28),
            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 14),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -14),
            badgeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        badge.isHidden = !showsSaveBadge
        updateAppearance()
    }

    required init?(coder: NSCoder) { nil }

    /// Populates the row from a loaded product: title = plan + per-week price,
    /// detail = full localized price. All amounts come from StoreKit, never hard-coded.
    func configure(product: ApphudProduct, planName: String) {
        self.product = product
        let trial = product.hasFreeTrial ? " · Free trial" : ""
        if let weekly = product.weeklyPriceString {
            titleLabel.text = "\(planName)  \(weekly) / week\(trial)"
        } else {
            titleLabel.text = "\(planName)\(trial)"
        }
        detailLabel.text = product.displayPriceString ?? " "
    }

    private func updateAppearance() {
        borderGradient.update(colors: isSelected
            ? AppColor.inputGradient
            : [AppColor.separator, AppColor.separator])
    }
}
