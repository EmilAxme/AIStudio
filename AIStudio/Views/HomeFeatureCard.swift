import UIKit

// MARK: - HomeFeatureCard
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
        layer.cornerRadius = 20
        clipsToBounds = true

        if isFeatured {
            let gradient = GradientView(
                colors: [UIColor(hex: 0x98C6F7), UIColor(hex: 0xEB5B92)],
                startPoint: CGPoint(x: 0.05, y: 0),
                endPoint: CGPoint(x: 0.95, y: 1)
            )
            gradient.isUserInteractionEnabled = false
            gradient.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(gradient, at: 0)
            gradient.pinToEdges(of: self)
        } else {
            backgroundColor = AppColor.surface
        }

        let iconSize: CGFloat = isFeatured ? 44 : 38
        iconBackground.backgroundColor = UIColor.white.withAlphaComponent(isFeatured ? 0.15 : 0.07)
        iconBackground.layer.cornerRadius = iconSize / 2
        let glyph: UIView
        let glyphSize: CGFloat = isFeatured ? 24 : 22
        if isFeatured {
            iconView.image = UIImage(named: symbol)
            iconView.tintColor = .white
            iconView.contentMode = .scaleAspectFit
            glyph = iconView
        } else {
            glyph = GradientIconView(imageName: symbol)
        }
        glyph.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.font = AppFont.font(isFeatured ? 20 : 16, isFeatured ? .medium : .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        subtitleLabel.text = subtitle
        subtitleLabel.font = AppFont.font(isFeatured ? 14 : 12, .regular)
        subtitleLabel.textColor = isFeatured ? UIColor.white.withAlphaComponent(0.7) : AppColor.secondaryText
        subtitleLabel.numberOfLines = 1
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.85

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 5
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubviews(iconBackground, glyph, textStack)
        NSLayoutConstraint.activate([
            iconBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconBackground.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            iconBackground.widthAnchor.constraint(equalToConstant: iconSize),
            iconBackground.heightAnchor.constraint(equalToConstant: iconSize),
            glyph.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            glyph.widthAnchor.constraint(equalToConstant: glyphSize),
            glyph.heightAnchor.constraint(equalToConstant: glyphSize),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])

        if isFeatured {
            actionPill.backgroundColor = UIColor.white.withAlphaComponent(0.26)
            actionPill.layer.cornerRadius = 17
            actionLabel.text = "Ready in seconds"
            actionLabel.font = AppFont.font(12, .medium)
            actionLabel.textColor = .white
            let playCircle = UIView()
            playCircle.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            playCircle.layer.cornerRadius = 10
            playCircle.translatesAutoresizingMaskIntoConstraints = false
            actionIcon.image = UIImage(systemName: "play.fill")
            actionIcon.tintColor = UIColor(hex: 0xC04E83)
            actionIcon.contentMode = .scaleAspectFit
            actionIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
            addSubviews(actionPill, actionLabel, playCircle, actionIcon)
            NSLayoutConstraint.activate([
                actionPill.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                actionPill.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
                actionPill.heightAnchor.constraint(equalToConstant: 34),
                actionLabel.leadingAnchor.constraint(equalTo: actionPill.leadingAnchor, constant: 14),
                actionLabel.centerYAnchor.constraint(equalTo: actionPill.centerYAnchor),
                playCircle.leadingAnchor.constraint(equalTo: actionLabel.trailingAnchor, constant: 8),
                playCircle.trailingAnchor.constraint(equalTo: actionPill.trailingAnchor, constant: -5),
                playCircle.centerYAnchor.constraint(equalTo: actionPill.centerYAnchor),
                playCircle.widthAnchor.constraint(equalToConstant: 20),
                playCircle.heightAnchor.constraint(equalToConstant: 20),
                actionIcon.centerXAnchor.constraint(equalTo: playCircle.centerXAnchor),
                actionIcon.centerYAnchor.constraint(equalTo: playCircle.centerYAnchor),
                textStack.topAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: 36)
            ])
        } else {
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        }
    }

    required init?(coder: NSCoder) { nil }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return nil }
        return bounds.contains(point) ? self : nil
    }
}
