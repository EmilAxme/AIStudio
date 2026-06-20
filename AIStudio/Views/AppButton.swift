import UIKit

final class GradientButton: UIButton {
    private let gradientView = GradientView(colors: AppColor.inputGradient)
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(title: String) {
        super.init(frame: .zero)
        layer.cornerRadius = Layout.pillRadius
        clipsToBounds = true
        gradientView.isUserInteractionEnabled = false
        insertSubview(gradientView, at: 0)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.pinToEdges(of: self)
        setTitle(title, for: .normal)
        titleLabel?.font = .App.medium(18)
        setTitleColor(.white, for: .normal)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.16
        }
    }

    func setLoading(_ isLoading: Bool) {
        isUserInteractionEnabled = !isLoading
        setTitleColor(isLoading ? .clear : .white, for: .normal)
        isLoading ? spinner.startAnimating() : spinner.stopAnimating()
    }
}
