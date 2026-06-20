import UIKit

final class HomeViewController: UIViewController {
    private let topGlow = GradientView(
        colors: [UIColor(hex: 0x45506D, alpha: 0.9), UIColor(hex: 0x5B325D, alpha: 0.65), AppColor.background],
        startPoint: CGPoint(x: 0, y: 0),
        endPoint: CGPoint(x: 1, y: 1)
    )
    private let settingsButton = UIButton(type: .system)
    private let sparkleIcon = UIImageView()
    private let titleLabel = UILabel()
    private let askControl = GradientBorderView(cornerRadius: 25)
    private let askLabel = UILabel()
    private let featuredCard = HomeFeatureCard(
        title: "Turn Photo\ninto Video",
        subtitle: "Animate  •  Templates",
        symbol: "photo.on.rectangle.angled",
        isFeatured: true
    )
    private let writingCard = HomeFeatureCard(
        title: "Fix & Improve\nWriting",
        subtitle: "Rewrite  •  Fix grammar",
        symbol: "wand.and.stars"
    )
    private let summaryCard = HomeFeatureCard(
        title: "Understand\nFaster",
        subtitle: "Summarize  •  Key points",
        symbol: "textformat"
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupActions()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupView() {
        view.backgroundColor = AppColor.background
        topGlow.translatesAutoresizingMaskIntoConstraints = false
        topGlow.isUserInteractionEnabled = false
        view.addSubview(topGlow)
        NSLayoutConstraint.activate([
            topGlow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGlow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGlow.topAnchor.constraint(equalTo: view.topAnchor),
            topGlow.heightAnchor.constraint(equalToConstant: 290)
        ])

        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.tintColor = UIColor.white.withAlphaComponent(0.46)
        settingsButton.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        settingsButton.layer.cornerRadius = 24
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        sparkleIcon.image = UIImage(systemName: "sparkles")
        sparkleIcon.tintColor = AppColor.lavender
        sparkleIcon.contentMode = .scaleAspectFit
        sparkleIcon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Your AI tools,\nready to go"
        titleLabel.font = .App.display(32)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let askIcon = UIImageView(image: UIImage(systemName: "sparkles"))
        askIcon.tintColor = .white
        askIcon.contentMode = .scaleAspectFit
        askIcon.translatesAutoresizingMaskIntoConstraints = false
        askLabel.text = "Ask anything..."
        askLabel.textColor = AppColor.secondaryText
        askLabel.font = .App.body(17)
        askLabel.translatesAutoresizingMaskIntoConstraints = false
        askControl.addContent(askIcon)
        askControl.addContent(askLabel)

        let cardsStack = UIStackView(arrangedSubviews: [writingCard, summaryCard])
        cardsStack.axis = .vertical
        cardsStack.spacing = 10
        cardsStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubviews(settingsButton, sparkleIcon, titleLabel, askControl, featuredCard, cardsStack)
        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 48),
            settingsButton.heightAnchor.constraint(equalToConstant: 48),
            sparkleIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 66),
            sparkleIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sparkleIcon.widthAnchor.constraint(equalToConstant: 58),
            sparkleIcon.heightAnchor.constraint(equalToConstant: 58),
            titleLabel.topAnchor.constraint(equalTo: sparkleIcon.bottomAnchor, constant: 15),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            askControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            askControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            askControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 22),
            askControl.heightAnchor.constraint(equalToConstant: 50),
            askIcon.leadingAnchor.constraint(equalTo: askControl.leadingAnchor, constant: 18),
            askIcon.centerYAnchor.constraint(equalTo: askControl.centerYAnchor),
            askIcon.widthAnchor.constraint(equalToConstant: 26),
            askIcon.heightAnchor.constraint(equalToConstant: 26),
            askLabel.leadingAnchor.constraint(equalTo: askIcon.trailingAnchor, constant: 14),
            askLabel.centerYAnchor.constraint(equalTo: askControl.centerYAnchor),
            featuredCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            featuredCard.topAnchor.constraint(equalTo: askControl.bottomAnchor, constant: 32),
            featuredCard.widthAnchor.constraint(equalToConstant: 140),
            featuredCard.heightAnchor.constraint(equalToConstant: 252),
            cardsStack.leadingAnchor.constraint(equalTo: featuredCard.trailingAnchor, constant: 10),
            cardsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            cardsStack.topAnchor.constraint(equalTo: featuredCard.topAnchor),
            writingCard.heightAnchor.constraint(equalToConstant: 121),
            summaryCard.heightAnchor.constraint(equalToConstant: 121)
        ])
    }

    private func setupActions() {
        settingsButton.addTarget(self, action: #selector(showPaywall), for: .touchUpInside)
        let chatTap = UITapGestureRecognizer(target: self, action: #selector(showChat))
        askControl.addGestureRecognizer(chatTap)
        writingCard.addTarget(self, action: #selector(showChat), for: .touchUpInside)
        summaryCard.addTarget(self, action: #selector(showChat), for: .touchUpInside)
        featuredCard.addTarget(self, action: #selector(showVideoGallery), for: .touchUpInside)
    }

    @objc private func showChat() {
        navigationController?.pushViewController(ChatViewController(), animated: true)
    }

    @objc private func showVideoGallery() {
        navigationController?.pushViewController(VideoGalleryViewController(), animated: true)
    }

    @objc private func showPaywall() {
        let paywall = PaywallViewController()
        paywall.modalPresentationStyle = .fullScreen
        present(paywall, animated: true)
    }
}
