import UIKit

/// A single history row: gradient glyph + title + timestamp on a translucent surface.
final class HistoryRowView: UIControl {
    init(item: HistoryItem) {
        super.init(frame: .zero)
        backgroundColor = UIColor(hex: 0x1F191F, alpha: 0.4)
        layer.cornerRadius = 24

        let icon = GradientIconView(imageName: "icGenerate")
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = AppFont.semibold(16)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail

        let timeLabel = UILabel()
        timeLabel.text = item.time
        timeLabel.font = AppFont.regular(14)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.5)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, timeLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubviews(icon, textStack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 72),
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            textStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 24),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { nil }
}
