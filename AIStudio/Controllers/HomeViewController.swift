import UIKit

final class HomeViewController: UIViewController {
    private let topGlow = GlowView(tint: UIColor(hex: 0x5A3A66), intensity: 0.6)
    private let settingsButton = UIButton(type: .system)
    private let sparkleLogo = SparkleLogoView()
    private let titleLabel = UILabel()
    private let askControl = GradientBorderView(
        cornerRadius: 25,
        fillColor: AppColor.field,
        borderColors: [UIColor(hex: 0x9DBEF0, alpha: 0.4), UIColor(hex: 0xE66298, alpha: 0.4)]
    )
    private let askLabel = UILabel()
    private let featuredCard = HomeFeatureCard(
        title: "Turn Photo\ninto Video",
        subtitle: "Instant  •  Templates",
        symbol: "photo.on.rectangle.angled",
        isFeatured: true
    )
    private let writingCard = HomeFeatureCard(
        title: "Fix & Improve\nWriting",
        subtitle: "Rewrite  •  Fix grammar",
        symbol: "pencil.and.scribble"
    )
    private let summaryCard = HomeFeatureCard(
        title: "Understand\nFaster",
        subtitle: "Summarize  •  Key points",
        symbol: "list.bullet.rectangle"
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
        view.addSubview(topGlow)
        NSLayoutConstraint.activate([
            topGlow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGlow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGlow.topAnchor.constraint(equalTo: view.topAnchor, constant: -40),
            topGlow.heightAnchor.constraint(equalToConstant: 320)
        ])

        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.tintColor = UIColor.white.withAlphaComponent(0.55)
        settingsButton.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        settingsButton.layer.cornerRadius = 20
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        sparkleLogo.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Your AI tools,\nready to go"
        titleLabel.font = AppFont.font(28, .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let askIconBackground = UIView()
        askIconBackground.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        askIconBackground.layer.cornerRadius = 9
        askIconBackground.translatesAutoresizingMaskIntoConstraints = false
        let askIcon = GradientIconView(symbol: "sparkles", pointSize: 15, weight: .medium)
        askIcon.translatesAutoresizingMaskIntoConstraints = false
        askIconBackground.addSubview(askIcon)
        askLabel.text = "Ask anything..."
        askLabel.textColor = AppColor.secondaryText
        askLabel.font = AppFont.font(16, .regular)
        askLabel.translatesAutoresizingMaskIntoConstraints = false
        askControl.addContent(askIconBackground)
        askControl.addContent(askLabel)

        let cardsStack = UIStackView(arrangedSubviews: [writingCard, summaryCard])
        cardsStack.axis = .vertical
        cardsStack.spacing = 12
        cardsStack.distribution = .fillEqually
        cardsStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubviews(settingsButton, sparkleLogo, titleLabel, askControl, featuredCard, cardsStack)
        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),

            sparkleLogo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 99),
            sparkleLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: sparkleLogo.bottomAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            askControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            askControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            askControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            askControl.heightAnchor.constraint(equalToConstant: 52),
            askIconBackground.leadingAnchor.constraint(equalTo: askControl.leadingAnchor, constant: 10),
            askIconBackground.centerYAnchor.constraint(equalTo: askControl.centerYAnchor),
            askIconBackground.widthAnchor.constraint(equalToConstant: 32),
            askIconBackground.heightAnchor.constraint(equalToConstant: 32),
            askIcon.centerXAnchor.constraint(equalTo: askIconBackground.centerXAnchor),
            askIcon.centerYAnchor.constraint(equalTo: askIconBackground.centerYAnchor),
            askLabel.leadingAnchor.constraint(equalTo: askIconBackground.trailingAnchor, constant: 12),
            askLabel.centerYAnchor.constraint(equalTo: askControl.centerYAnchor),

            featuredCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            featuredCard.topAnchor.constraint(equalTo: askControl.bottomAnchor, constant: 43),
            featuredCard.heightAnchor.constraint(equalToConstant: 293),

            cardsStack.leadingAnchor.constraint(equalTo: featuredCard.trailingAnchor, constant: 12),
            cardsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            cardsStack.topAnchor.constraint(equalTo: featuredCard.topAnchor),
            cardsStack.bottomAnchor.constraint(equalTo: featuredCard.bottomAnchor),
            featuredCard.widthAnchor.constraint(equalTo: cardsStack.widthAnchor)
        ])
    }

    private func setupActions() {
        settingsButton.addTarget(self, action: #selector(showPaywall), for: .touchUpInside)
        let chatTap = UITapGestureRecognizer(target: self, action: #selector(showChatEmpty))
        askControl.addGestureRecognizer(chatTap)
        writingCard.addTarget(self, action: #selector(showChat), for: .touchUpInside)
        summaryCard.addTarget(self, action: #selector(showChat), for: .touchUpInside)
        featuredCard.addTarget(self, action: #selector(showVideoGallery), for: .touchUpInside)
    }

    @objc private func showChat() {
        navigationController?.pushViewController(ChatViewController(), animated: true)
    }

    @objc private func showChatEmpty() {
        navigationController?.pushViewController(ChatViewController(startEmpty: true), animated: true)
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
