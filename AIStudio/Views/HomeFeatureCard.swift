import UIKit

final class HomeFeatureCard: UIControl {
    private let iconBackground = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionPill = UIView()
    private let actionLabel = UILabel()
    private let actionIcon = UIImageView()

    init(
        title: String,
        subtitle: String,
        symbol: String,
        isFeatured: Bool = false
    ) {
        super.init(frame: .zero)
        layer.cornerRadius = Layout.cardRadius
        clipsToBounds = true

        if isFeatured {
            let gradient = GradientView(colors: [UIColor(hex: 0x91C1EC), UIColor(hex: 0xA991CA), UIColor(hex: 0xC84680)])
            gradient.isUserInteractionEnabled = false
            gradient.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(gradient, at: 0)
            gradient.pinToEdges(of: self)
        } else {
            backgroundColor = AppColor.surface
        }

        iconBackground.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        iconBackground.layer.cornerRadius = 23
        iconView.image = UIImage(systemName: symbol)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        titleLabel.text = title
        titleLabel.font = .App.medium(isFeatured ? 20 : 17)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        subtitleLabel.text = subtitle
        subtitleLabel.font = .App.body(isFeatured ? 13 : 12)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        subtitleLabel.numberOfLines = 2

        addSubviews(iconBackground, iconView, titleLabel, subtitleLabel)
        NSLayoutConstraint.activate([
            iconBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconBackground.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            iconBackground.widthAnchor.constraint(equalToConstant: 46),
            iconBackground.heightAnchor.constraint(equalToConstant: 46),
            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 25),
            iconView.heightAnchor.constraint(equalToConstant: 25),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])

        if isFeatured {
            actionPill.backgroundColor = UIColor.white.withAlphaComponent(0.25)
            actionPill.layer.cornerRadius = 18
            actionLabel.text = "Ready in seconds"
            actionLabel.font = .App.body(12)
            actionLabel.textColor = .white
            actionIcon.image = UIImage(systemName: "play.fill")
            actionIcon.tintColor = .white
            actionIcon.contentMode = .scaleAspectFit
            addSubviews(actionPill, actionLabel, actionIcon)
            NSLayoutConstraint.activate([
                actionPill.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                actionPill.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                actionPill.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13),
                actionPill.heightAnchor.constraint(equalToConstant: 36),
                actionLabel.leadingAnchor.constraint(equalTo: actionPill.leadingAnchor, constant: 14),
                actionLabel.centerYAnchor.constraint(equalTo: actionPill.centerYAnchor),
                actionIcon.trailingAnchor.constraint(equalTo: actionPill.trailingAnchor, constant: -14),
                actionIcon.centerYAnchor.constraint(equalTo: actionPill.centerYAnchor),
                actionIcon.widthAnchor.constraint(equalToConstant: 16),
                actionIcon.heightAnchor.constraint(equalToConstant: 16)
            ])
        }
    }

    required init?(coder: NSCoder) { nil }
}
