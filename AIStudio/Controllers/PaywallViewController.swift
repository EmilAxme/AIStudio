import UIKit

final class PaywallViewController: UIViewController {
    private let topGlow = GradientView(
        colors: [UIColor(hex: 0x526080, alpha: 0.85), UIColor(hex: 0x6B365F, alpha: 0.7), AppColor.background],
        startPoint: CGPoint(x: 0, y: 0),
        endPoint: CGPoint(x: 1, y: 1)
    )
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
            topGlow.topAnchor.constraint(equalTo: view.topAnchor),
            topGlow.heightAnchor.constraint(equalToConstant: 280)
        ])

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = UIColor.white.withAlphaComponent(0.7)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let title = UILabel()
        title.text = "Create anything\nyou want"
        title.textColor = .white
        title.font = .App.display(34)
        title.numberOfLines = 2
        title.textAlignment = .center

        let benefits = UIStackView()
        benefits.axis = .vertical
        benefits.spacing = 18
        [
            ("sparkles", "Get results in seconds"),
            ("wand.and.stars", "Turn any text into better writing"),
            ("textformat", "Simplify complex information"),
            ("photo.on.rectangle.angled", "Create content with AI templates")
        ].forEach { symbol, text in
            benefits.addArrangedSubview(benefitRow(symbol: symbol, text: text))
        }

        let cancel = UILabel()
        cancel.text = "◴  Cancel Anytime"
        cancel.textColor = AppColor.mutedText
        cancel.font = .App.body(14)
        cancel.textAlignment = .center

        let footer = UIStackView()
        footer.axis = .horizontal
        footer.distribution = .equalCentering
        ["Privacy Policy", "Restore Purchases", "Terms of Use"].forEach { text in
            let label = UILabel()
            label.text = text
            label.textColor = AppColor.mutedText
            label.font = .App.body(12)
            footer.addArrangedSubview(label)
        }

        view.addSubviews(close, title, benefits, yearly, monthly, cancel, unlock, footer)
        NSLayoutConstraint.activate([
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            close.widthAnchor.constraint(equalToConstant: 40),
            close.heightAnchor.constraint(equalToConstant: 40),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 170),
            benefits.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            benefits.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            benefits.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 42),
            yearly.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            yearly.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            yearly.topAnchor.constraint(equalTo: benefits.bottomAnchor, constant: 40),
            monthly.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            monthly.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            monthly.topAnchor.constraint(equalTo: yearly.bottomAnchor, constant: 12),
            cancel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancel.topAnchor.constraint(equalTo: monthly.bottomAnchor, constant: 18),
            unlock.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            unlock.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            unlock.topAnchor.constraint(equalTo: cancel.bottomAnchor, constant: 20),
            unlock.heightAnchor.constraint(equalToConstant: 58),
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        yearly.addTarget(self, action: #selector(yearlyTapped), for: .touchUpInside)
        monthly.addTarget(self, action: #selector(monthlyTapped), for: .touchUpInside)
        unlock.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
    }

    private func benefitRow(symbol: String, text: String) -> UIView {
        let view = UIView()
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = AppColor.lavender
        icon.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .App.body(18)
        view.addSubviews(icon, label)
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 30),
            icon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 26),
            icon.heightAnchor.constraint(equalToConstant: 26),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 18),
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
