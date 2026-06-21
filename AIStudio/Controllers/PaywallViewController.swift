import UIKit
import ApphudSDK

final class PaywallViewController: UIViewController {
    private let topGlow = GlowView(tint: UIColor(hex: 0x5A3A66), intensity: 0.55)
    private let yearly = PlanOptionView(showsSaveBadge: true, placeholderTitle: "Year")
    private let monthly = PlanOptionView(showsSaveBadge: false, placeholderTitle: "Month")
    private let unlock = GradientButton(title: "Unlock now")
    private let restoreLabel = UILabel()
    private var selectedPlanView: PlanOptionView

    private let subscription: SubscriptionService

    /// Invoked after the user successfully unlocks premium (purchase or restore),
    /// so the gated action that opened this paywall can proceed without a relaunch.
    var onUnlocked: (() -> Void)?

    init(subscription: SubscriptionService = AppServices.subscription) {
        self.subscription = subscription
        self.selectedPlanView = yearly
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        updateSelection()
        loadProducts()
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
        close.setImage(UIImage(named: "icClose"), for: .normal)
        close.tintColor = UIColor.white.withAlphaComponent(0.85)
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
        let rows: [(GradientIconView, String)] = [
            (GradientIconView(imageName: "icGenerate"), "Get results in seconds"),
            (GradientIconView(imageName: "icMagicPencil"), "Turn any text into better writing"),
            (GradientIconView(imageName: "icPrompt"), "Simplify complex information"),
            (GradientIconView(imageName: "icImageToImage"), "Create content with AI templates")
        ]
        rows.forEach { benefits.addArrangedSubview(benefitRow(iconView: $0.0, text: $0.1)) }

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
        let footerItems = ["Privacy Policy", "Restore Purchases", "Terms of Use"]
        for text in footerItems {
            let label = UILabel()
            label.text = text
            label.textColor = AppColor.mutedText
            label.font = AppFont.font(11, .regular)
            if text == "Restore Purchases" {
                label.isUserInteractionEnabled = true
                label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(restoreTapped)))
                restoreLabel.text = text  // keep a typed reference for loading state
            }
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

    private func benefitRow(iconView icon: GradientIconView, text: String) -> UIView {
        let view = UIView()
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

    // MARK: - Products

    /// Loads the `main` paywall and binds real products to the two plan rows.
    private func loadProducts() {
        unlock.setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            let paywall = await self.subscription.loadPaywall()
            await MainActor.run {
                self.unlock.setLoading(false)
                guard let products = paywall?.products, !products.isEmpty else {
                    self.presentLoadFailure()
                    return
                }
                self.bind(products: products)
            }
        }
    }

    /// Assigns products to the yearly/monthly rows by their subscription period,
    /// falling back to source order when the period is unknown.
    private func bind(products: [ApphudProduct]) {
        let yearlyProduct = products.first { $0.skProduct?.subscriptionPeriod?.unit == .year }
        let monthlyProduct = products.first { $0.skProduct?.subscriptionPeriod?.unit == .month }

        let resolvedYearly = yearlyProduct ?? products.first
        let resolvedMonthly = monthlyProduct ?? products.dropFirst().first ?? products.first

        if let resolvedYearly { yearly.configure(product: resolvedYearly, planName: "Year") }
        if let resolvedMonthly { monthly.configure(product: resolvedMonthly, planName: "Month") }

        // Keep the previously selected row if it now has a product; else default to yearly.
        if selectedPlanView.product == nil { selectedPlanView = yearly }
        updateSelection()
    }

    private func presentLoadFailure() {
        let alert = UIAlertController(
            title: "Не удалось загрузить",
            message: "Подписки временно недоступны. Проверьте соединение и попробуйте ещё раз.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in self?.loadProducts() })
        alert.addAction(UIAlertAction(title: "Закрыть", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Selection

    private func updateSelection() {
        yearly.isSelected = selectedPlanView === yearly
        monthly.isSelected = selectedPlanView === monthly
    }

    @objc private func yearlyTapped() { selectedPlanView = yearly; updateSelection() }
    @objc private func monthlyTapped() { selectedPlanView = monthly; updateSelection() }

    // MARK: - Purchase / Restore

    @objc private func unlockTapped() {
        guard let product = selectedPlanView.product else {
            presentLoadFailure()
            return
        }
        unlock.setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            let result = await self.subscription.purchase(product)
            await MainActor.run {
                self.unlock.setLoading(false)
                switch result {
                case .success(let unlocked):
                    if unlocked { self.handleUnlocked() }
                case .failure(let error):
                    self.presentError(error)
                }
            }
        }
    }

    @objc private func restoreTapped() {
        unlock.setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            let result = await self.subscription.restore()
            await MainActor.run {
                self.unlock.setLoading(false)
                switch result {
                case .success(let unlocked):
                    unlocked ? self.handleUnlocked() : self.presentNothingToRestore()
                case .failure(let error):
                    self.presentError(error)
                }
            }
        }
    }

    /// Unlock-without-relaunch: dismiss and let the opener run the gated action.
    private func handleUnlocked() {
        let completion = onUnlocked
        dismiss(animated: true) { completion?() }
    }

    private func presentError(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(title: "Покупка не завершена", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func presentNothingToRestore() {
        let alert = UIAlertController(
            title: "Покупки не найдены",
            message: "Активные подписки для восстановления не найдены.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func closeTapped() { dismiss(animated: true) }
}
