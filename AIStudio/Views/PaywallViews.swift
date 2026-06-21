import UIKit

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

    init(plan: SubscriptionPlan) {
        super.init(frame: .zero)
        layer.cornerRadius = Layout.rowRadius
        clipsToBounds = true

        borderGradient.isUserInteractionEnabled = false
        inner.backgroundColor = AppColor.background
        inner.layer.cornerRadius = Layout.rowRadius - borderWidth
        inner.isUserInteractionEnabled = false

        titleLabel.text = plan.title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        detailLabel.text = plan.detail
        detailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        detailLabel.textColor = AppColor.mutedText

        badge.layer.cornerRadius = 14
        badge.clipsToBounds = true
        badge.isUserInteractionEnabled = false
        badgeLabel.text = "SAVE 80%"
        badgeLabel.textColor = .white
        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
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

            titleLabel.leadingAnchor.constraint(equalTo: inner.leadingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: inner.topAnchor, constant: 14),
            detailLabel.leadingAnchor.constraint(equalTo: inner.leadingAnchor, constant: 18),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            badge.trailingAnchor.constraint(equalTo: inner.trailingAnchor, constant: -16),
            badge.centerYAnchor.constraint(equalTo: inner.centerYAnchor),
            badge.heightAnchor.constraint(equalToConstant: 28),
            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 14),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -14),
            badgeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        badge.isHidden = plan != .yearly
        updateAppearance()
    }

    required init?(coder: NSCoder) { nil }

    private func updateAppearance() {
        borderGradient.update(colors: isSelected
            ? AppColor.inputGradient
            : [AppColor.separator, AppColor.separator])
    }
}
