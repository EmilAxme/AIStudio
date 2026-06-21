import UIKit

final class PaywallViewController: UIViewController {
    private let topGlow = GlowView(tint: UIColor(hex: 0x5A3A66), intensity: 0.55)
    private let yearly = PlanOptionView(plan: .yearly)
    private let monthly = PlanOptionView(plan: .monthly)
    private let unlock = GradientButton(title: "Unlock now")
    private var selectedPlan: SubscriptionPlan = .yearly

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        updateSelection()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupView() {
        topGlow.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topGlow)
        NSLayoutConstraint.activate([
            topGlow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGlow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGlow.topAnchor.constraint(equalTo: view.topAnchor, constant: -60),
            topGlow.heightAnchor.constraint(equalToConstant: 340)
        ])

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = UIColor.white.withAlphaComponent(0.85)
        close.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 17, weight: .medium), forImageIn: .normal)
        close.contentHorizontalAlignment = .leading
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let title = UILabel()
        title.text = "Create anything\nyou want"
        title.textColor = .white
        title.font = AppFont.font(34, .bold)
        title.numberOfLines = 2
        title.textAlignment = .left

        let benefits = UIStackView()
        benefits.axis = .vertical
        benefits.spacing = 14
        [
            ("sparkles", "Get results in seconds"),
            ("pencil.and.scribble", "Turn any text into better writing"),
            ("list.bullet.rectangle", "Simplify complex information"),
            ("square.grid.2x2", "Create content with AI templates")
        ].forEach { symbol, text in
            benefits.addArrangedSubview(benefitRow(symbol: symbol, text: text))
        }

        let cancelIcon = UIImageView(image: UIImage(systemName: "clock.arrow.circlepath"))
        cancelIcon.tintColor = AppColor.mutedText
        cancelIcon.contentMode = .scaleAspectFit
        cancelIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        let cancelLabel = UILabel()
        cancelLabel.text = "Cancel Anytime"
        cancelLabel.textColor = AppColor.mutedText
        cancelLabel.font = AppFont.font(13, .regular)
        let cancel = UIStackView(arrangedSubviews: [cancelIcon, cancelLabel])
        cancel.spacing = 5
        cancel.alignment = .center

        let footer = UIStackView()
        footer.axis = .horizontal
        footer.distribution = .equalCentering
        ["Privacy Policy", "Restore Purchases", "Terms of Use"].forEach { text in
            let label = UILabel()
            label.text = text
            label.textColor = AppColor.mutedText
            label.font = AppFont.font(11, .regular)
            footer.addArrangedSubview(label)
        }

        view.addSubviews(close, title, benefits, yearly, monthly, cancel, unlock, footer)
        NSLayoutConstraint.activate([
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            close.widthAnchor.constraint(equalToConstant: 40),
            close.heightAnchor.constraint(equalToConstant: 40),

            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 164),

            benefits.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            benefits.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            benefits.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 38),

            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),

            unlock.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            unlock.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            unlock.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -16),
            unlock.heightAnchor.constraint(equalToConstant: 52),

            cancel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancel.bottomAnchor.constraint(equalTo: unlock.topAnchor, constant: -16),

            monthly.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            monthly.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            monthly.bottomAnchor.constraint(equalTo: cancel.topAnchor, constant: -16),

            yearly.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            yearly.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            yearly.bottomAnchor.constraint(equalTo: monthly.topAnchor, constant: -12)
        ])
        yearly.addTarget(self, action: #selector(yearlyTapped), for: .touchUpInside)
        monthly.addTarget(self, action: #selector(monthlyTapped), for: .touchUpInside)
        unlock.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
    }

    private func benefitRow(symbol: String, text: String) -> UIView {
        let view = UIView()
        let icon = GradientIconView(symbol: symbol, pointSize: 17, weight: .semibold)
        icon.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = AppFont.font(15, .regular)
        view.addSubviews(icon, label)
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 26),
            icon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }

    private func updateSelection() {
        yearly.isSelected = selectedPlan == .yearly
        monthly.isSelected = selectedPlan == .monthly
    }

    @objc private func yearlyTapped() { selectedPlan = .yearly; updateSelection() }
    @objc private func monthlyTapped() { selectedPlan = .monthly; updateSelection() }

    @objc private func unlockTapped() {
        AppServices.subscription.activate(plan: selectedPlan)
        dismiss(animated: true)
    }

    @objc private func closeTapped() { dismiss(animated: true) }
}
