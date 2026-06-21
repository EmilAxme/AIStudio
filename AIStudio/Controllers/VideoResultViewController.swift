import UIKit

/// AI Video result screen: runs a mock generation (loading orb) then shows the
/// generated result with Share / Download actions. Error state offers retry.
final class VideoResultViewController: UIViewController {
    private let request: VideoRequest
    private var shouldFail: Bool

    private let resultImageView = UIImageView()
    private let shareButton = UIButton(type: .system)
    private let downloadButton = GradientButton(title: "Download")
    private let actionsStack = UIStackView()

    private let orb = GradientView(colors: AppColor.inputGradient)
    private let statusTitle = UILabel()
    private let statusSubtitle = UILabel()
    private let loadingStack = UIStackView()

    private var state: ViewState = .loading { didSet { renderState() } }

    init(request: VideoRequest, shouldFail: Bool = false) {
        self.request = request
        self.shouldFail = shouldFail
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        renderState()
        generate()
    }

    private func setupView() {
        let header = ScreenHeaderView(title: "Result") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        resultImageView.image = UIImage(named: request.imageName)
        resultImageView.contentMode = .scaleAspectFill
        resultImageView.layer.cornerRadius = 24
        resultImageView.clipsToBounds = true
        resultImageView.translatesAutoresizingMaskIntoConstraints = false

        shareButton.setTitle("Share", for: .normal)
        shareButton.titleLabel?.font = AppFont.semibold(17)
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.backgroundColor = AppColor.surface
        shareButton.layer.cornerRadius = Layout.buttonRadius
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false

        actionsStack.axis = .horizontal
        actionsStack.distribution = .fillEqually
        actionsStack.spacing = 12
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.addArrangedSubview(shareButton)
        actionsStack.addArrangedSubview(downloadButton)

        // Loading state (orb + text)
        orb.layer.cornerRadius = 70
        orb.clipsToBounds = true
        orb.translatesAutoresizingMaskIntoConstraints = false
        orb.widthAnchor.constraint(equalToConstant: 140).isActive = true
        orb.heightAnchor.constraint(equalToConstant: 140).isActive = true
        let orbHighlight = UIView()
        orbHighlight.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        orbHighlight.layer.cornerRadius = 22
        orbHighlight.translatesAutoresizingMaskIntoConstraints = false
        orb.addSubview(orbHighlight)
        NSLayoutConstraint.activate([
            orbHighlight.widthAnchor.constraint(equalToConstant: 44),
            orbHighlight.heightAnchor.constraint(equalToConstant: 30),
            orbHighlight.topAnchor.constraint(equalTo: orb.topAnchor, constant: 26),
            orbHighlight.leadingAnchor.constraint(equalTo: orb.leadingAnchor, constant: 34)
        ])

        statusTitle.font = AppFont.semibold(18)
        statusTitle.textColor = .white
        statusTitle.textAlignment = .center
        statusSubtitle.font = AppFont.regular(14)
        statusSubtitle.textColor = AppColor.secondaryText
        statusSubtitle.textAlignment = .center
        statusSubtitle.numberOfLines = 0

        loadingStack.axis = .vertical
        loadingStack.alignment = .center
        loadingStack.spacing = 10
        loadingStack.setCustomSpacing(28, after: orb)
        loadingStack.translatesAutoresizingMaskIntoConstraints = false
        loadingStack.addArrangedSubview(orb)
        loadingStack.addArrangedSubview(statusTitle)
        loadingStack.addArrangedSubview(statusSubtitle)

        view.addSubview(resultImageView)
        view.addSubview(actionsStack)
        view.addSubview(loadingStack)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            resultImageView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            resultImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            resultImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            resultImageView.bottomAnchor.constraint(equalTo: actionsStack.topAnchor, constant: -20),

            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            actionsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            actionsStack.heightAnchor.constraint(equalToConstant: 52),

            loadingStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            loadingStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])

        shareButton.addAction(UIAction { [weak self] _ in self?.presentShareSheet() }, for: .touchUpInside)
        downloadButton.addAction(UIAction { [weak self] _ in self?.presentSavedAlert() }, for: .touchUpInside)
    }

    private func generate() {
        state = .loading
        AppServices.video.generate(request: request, shouldFail: shouldFail) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success: self.state = .success
            case .failure(let error): self.state = .error(error.localizedDescription)
            }
        }
    }

    private func renderState() {
        switch state {
        case .idle, .loading:
            loadingStack.isHidden = false
            resultImageView.isHidden = true
            actionsStack.isHidden = true
            statusTitle.text = "Generating..."
            statusTitle.textColor = .white
            statusSubtitle.text = "We're creating the best result for you"
            startOrbPulse()
        case .success:
            loadingStack.isHidden = true
            resultImageView.isHidden = false
            actionsStack.isHidden = false
        case .error(let message):
            loadingStack.isHidden = false
            resultImageView.isHidden = true
            actionsStack.isHidden = true
            orb.layer.removeAllAnimations()
            statusTitle.text = "Something went wrong"
            statusSubtitle.text = message
            addRetryIfNeeded()
        }
    }

    private func addRetryIfNeeded() {
        guard loadingStack.arrangedSubviews.count == 3 else { return }
        let retry = GradientButton(title: "Try again")
        retry.translatesAutoresizingMaskIntoConstraints = false
        retry.heightAnchor.constraint(equalToConstant: 50).isActive = true
        retry.widthAnchor.constraint(equalToConstant: 200).isActive = true
        retry.addAction(UIAction { [weak self] _ in
            self?.shouldFail = false
            self?.loadingStack.arrangedSubviews.last.flatMap { $0 as? GradientButton }?.removeFromSuperview()
            self?.generate()
        }, for: .touchUpInside)
        loadingStack.setCustomSpacing(24, after: statusSubtitle)
        loadingStack.addArrangedSubview(retry)
    }

    private func startOrbPulse() {
        orb.layer.removeAllAnimations()
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.92
        pulse.toValue = 1.0
        pulse.duration = 0.8
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        orb.layer.add(pulse, forKey: "pulse")
    }

    private func presentShareSheet() {
        let items: [Any] = [resultImageView.image as Any].compactMap { $0 }
        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(sheet, animated: true)
    }

    private func presentSavedAlert() {
        let alert = UIAlertController(title: "Saved", message: "The video has been saved to your gallery.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
