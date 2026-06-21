import UIKit

/// Reusable top bar: back chevron on the left, centered title. 44pt tall.
final class ScreenHeaderView: UIView {
    private let onBack: () -> Void

    init(title: String, titleSize: CGFloat = 17, onBack: @escaping () -> Void) {
        self.onBack = onBack
        super.init(frame: .zero)

        let back = UIButton(type: .system)
        back.setImage(UIImage(named: "icArrow"), for: .normal)
        back.tintColor = .white
        back.addAction(UIAction { [weak self] _ in self?.onBack() }, for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppFont.semibold(titleSize)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubviews(back, titleLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            back.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            back.centerYAnchor.constraint(equalTo: centerYAnchor),
            back.widthAnchor.constraint(equalToConstant: 34),
            back.heightAnchor.constraint(equalToConstant: 34),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }
}
