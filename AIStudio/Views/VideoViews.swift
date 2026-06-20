import UIKit

final class VideoTemplateCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoTemplateCell"

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 24
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        imageView.pinToEdges(of: contentView)
    }

    required init?(coder: NSCoder) { nil }

    func configure(image: UIImage?) {
        imageView.image = image
    }
}

final class FormOptionView: UIControl {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String, value: String) {
        super.init(frame: .zero)
        backgroundColor = AppColor.surface
        layer.cornerRadius = Layout.pillRadius
        titleLabel.text = title
        titleLabel.textColor = AppColor.secondaryText
        titleLabel.font = .App.body(18)
        valueLabel.text = value
        valueLabel.textColor = .white
        valueLabel.font = .App.medium(18)
        addSubviews(titleLabel, valueLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 58),
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
        layer.cornerRadius = 22
        clipsToBounds = true
        gradient.translatesAutoresizingMaskIntoConstraints = false
        inner.backgroundColor = AppColor.background
        inner.layer.cornerRadius = 21
        inner.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        spinner.color = AppColor.lavender
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubviews(gradient, inner, icon, spinner)
        gradient.pinToEdges(of: self)
        NSLayoutConstraint.activate([
            inner.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1.25),
            inner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1.25),
            inner.topAnchor.constraint(equalTo: topAnchor, constant: 1.25),
            inner.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.25),
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 30),
            icon.heightAnchor.constraint(equalToConstant: 30),
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
