import UIKit

final class VideoTemplateCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoTemplateCell"

    private let imageView = UIImageView()
    private let scrim = GradientView(
        colors: [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.55)],
        startPoint: CGPoint(x: 0.5, y: 0.45),
        endPoint: CGPoint(x: 0.5, y: 1)
    )
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 14
        contentView.clipsToBounds = true
        contentView.backgroundColor = AppColor.surface
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrim.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        contentView.addSubview(scrim)
        contentView.addSubview(titleLabel)
        imageView.pinToEdges(of: contentView)
        NSLayoutConstraint.activate([
            scrim.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrim.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(image: UIImage?, title: String) {
        imageView.image = image
        titleLabel.text = title
    }
}

final class FormOptionView: UIControl {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String, value: String) {
        super.init(frame: .zero)
        backgroundColor = AppColor.surface
        layer.cornerRadius = Layout.rowRadius
        titleLabel.text = title
        titleLabel.textColor = AppColor.secondaryText
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        valueLabel.text = value
        valueLabel.textColor = .white
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        addSubviews(titleLabel, valueLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }
}

final class UploadTile: UIControl {
    private let icon = UIImageView(image: UIImage(systemName: "plus"))
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let gradient = GradientView(colors: AppColor.inputGradient)
    private let inner = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true
        gradient.translatesAutoresizingMaskIntoConstraints = false
        inner.backgroundColor = AppColor.background
        inner.layer.cornerRadius = 10.5
        inner.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .light)
        icon.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = AppColor.lavender
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubviews(gradient, inner, icon, spinner)
        gradient.pinToEdges(of: self)
        NSLayoutConstraint.activate([
            inner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1.5),
            inner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1.5),
            inner.topAnchor.constraint(equalTo: topAnchor, constant: 1.5),
            inner.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.5),
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func setLoading(_ isLoading: Bool) {
        icon.isHidden = isLoading
        isLoading ? spinner.startAnimating() : spinner.stopAnimating()
    }
}
