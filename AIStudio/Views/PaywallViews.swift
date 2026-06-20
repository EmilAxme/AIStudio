import UIKit

final class PlanOptionView: UIControl {
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let badge = GradientView(colors: AppColor.inputGradient)
    private let badgeLabel = UILabel()

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    init(plan: SubscriptionPlan) {
        super.init(frame: .zero)
        layer.cornerRadius = 26
        layer.borderWidth = 1.2
        titleLabel.text = plan.title
        titleLabel.font = .App.medium(19)
        titleLabel.textColor = .white
        detailLabel.text = plan.detail
        detailLabel.font = .App.body(16)
        detailLabel.textColor = AppColor.mutedText
        badge.layer.cornerRadius = 18
        badge.clipsToBounds = true
        badgeLabel.text = "SAVE 80%"
        badgeLabel.textColor = .white
        badgeLabel.font = .App.medium(14)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeLabel)
        addSubviews(titleLabel, detailLabel, badge)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 84),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            detailLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            badge.centerYAnchor.constraint(equalTo: centerYAnchor),
            badge.heightAnchor.constraint(equalToConstant: 36),
            badge.widthAnchor.constraint(equalToConstant: 122),
            badgeLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        badge.isHidden = plan != .yearly
        updateAppearance()
    }

    required init?(coder: NSCoder) { nil }

    private func updateAppearance() {
        layer.borderColor = (isSelected ? AppColor.pink : AppColor.separator).cgColor
        backgroundColor = isSelected ? UIColor.black.withAlphaComponent(0.08) : .clear
    }
}
