import UIKit

final class GradientButton: UIButton {
    private let gradientView = GradientView(
        colors: AppColor.inputGradient,
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
    )
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(title: String) {
        super.init(frame: .zero)
        layer.cornerRadius = Layout.buttonRadius
        clipsToBounds = true
        gradientView.isUserInteractionEnabled = false
        insertSubview(gradientView, at: 0)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.pinToEdges(of: self)
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        setTitleColor(.white, for: .normal)
        setTitleColor(AppColor.mutedText, for: .disabled)
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
            gradientView.isHidden = !isEnabled
            backgroundColor = isEnabled ? .clear : AppColor.disabled
        }
    }

    func setLoading(_ isLoading: Bool) {
        isUserInteractionEnabled = !isLoading
        titleLabel?.layer.opacity = isLoading ? 0 : 1
        isLoading ? spinner.startAnimating() : spinner.stopAnimating()
    }
}
