import UIKit
import StoreKit
import ApphudSDK

final class PaywallViewController: UIViewController {
    private let topGlow = GlowView(tint: UIColor(hex: 0x5A3A66), intensity: 0.55)
    private let yearly = PlanOptionView(placeholderTitle: "Year".localized)
    private let monthly = PlanOptionView(placeholderTitle: "Month".localized)
    private let unlock = GradientButton(title: "Unlock now".localized)
    private let restoreLabel = UILabel()
    private var selectedPlanView: PlanOptionView

    private let subscription: SubscriptionService
    private var didUnlock = false

    var onUnlocked: (() -> Void)?

    init(subscription: SubscriptionService = AppServices.subscription) {
        self.subscription = subscription
        self.selectedPlanView = yearly
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        updateSelection()
        loadProducts()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionStatusChanged),
            name: SubscriptionService.statusDidChange,
            object: nil
        )
    }

    @objc private func subscriptionStatusChanged() {
        if subscription.isPremium { handleUnlocked() }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Setup

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
        title.text = "Create anything\nyou want".localized
        title.textColor = .white
        title.font = AppFont.font(34, .bold)
        title.numberOfLines = 2
        title.textAlignment = .left

        let benefits = UIStackView()
        benefits.axis = .vertical
        benefits.spacing = 14
        let rows: [(GradientIconView, String)] = [
            (GradientIconView(imageName: "icGenerate"), "Get results in seconds".localized),
            (GradientIconView(imageName: "icMagicPencil"), "Turn any text into better writing".localized),
            (GradientIconView(imageName: "icPrompt"), "Simplify complex information".localized),
            (GradientIconView(imageName: "icImageToImage"), "Create content with AI templates".localized)
        ]
        rows.forEach { benefits.addArrangedSubview(benefitRow(iconView: $0.0, text: $0.1)) }

        let cancelIcon = UIImageView(image: UIImage(systemName: "clock.arrow.circlepath"))
        cancelIcon.tintColor = AppColor.mutedText
        cancelIcon.contentMode = .scaleAspectFit
        cancelIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        let cancelLabel = UILabel()
        cancelLabel.text = "Cancel Anytime".localized
        cancelLabel.textColor = AppColor.mutedText
        cancelLabel.font = AppFont.font(13, .regular)
        let cancel = UIStackView(arrangedSubviews: [cancelIcon, cancelLabel])
        cancel.spacing = 5
        cancel.alignment = .center

        let footer = UIStackView()
        footer.axis = .horizontal
        footer.distribution = .equalCentering
        let footerItems = ["Privacy Policy".localized, "Restore Purchases".localized, "Terms of Use".localized]
        for text in footerItems {
            let label = UILabel()
            label.text = text
            label.textColor = AppColor.mutedText
            label.font = AppFont.font(11, .regular)
            if text == "Restore Purchases".localized {
                label.isUserInteractionEnabled = true
                label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(restoreTapped)))
                restoreLabel.text = text
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

    private func loadProducts() {
        unlock.setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            let paywall = await self.subscription.loadPaywall()
            await MainActor.run {
                self.unlock.setLoading(false)
                guard let paywall else {
                    self.presentLoadFailure()
                    return
                }
                let resolved = paywall.products.filter { $0.skProduct != nil }
                guard !resolved.isEmpty else {
                    #if DEBUG
                    let ids = paywall.products.map { $0.productId }.joined(separator: ", ")
                    NSLog("[Apphud] paywall '\(paywall.identifier)' has no StoreKit-resolved products. Ids: [\(ids)]. Add these to AIStudio.storekit (or App Store Connect).")
                    #endif
                    self.presentProductsUnavailable()
                    return
                }
                self.bind(products: resolved)
            }
        }
    }

    private func bind(products: [ApphudProduct]) {
        let yearlyByPeriod = products.first { $0.skProduct?.subscriptionPeriod?.unit == .year }
        let monthlyByPeriod = products.first { $0.skProduct?.subscriptionPeriod?.unit == .month }

        let resolvedYearly: ApphudProduct?
        let resolvedMonthly: ApphudProduct?
        if let yearlyByPeriod, let monthlyByPeriod, yearlyByPeriod !== monthlyByPeriod {
            resolvedYearly = yearlyByPeriod
            resolvedMonthly = monthlyByPeriod
        } else {
            resolvedYearly = products.first
            resolvedMonthly = products.count > 1 ? products[1] : nil
        }

        configureRow(yearly, with: resolvedYearly, fallbackName: "Year".localized)
        configureRow(monthly, with: resolvedMonthly, fallbackName: "Month".localized)

        yearly.setSaveBadge(percent: Self.savingsPercent(cheaper: resolvedYearly, baseline: resolvedMonthly))

        if selectedPlanView.product == nil || selectedPlanView.isHidden {
            selectedPlanView = resolvedYearly != nil ? yearly : monthly
        }
        updateSelection()
    }

    private func configureRow(_ row: PlanOptionView, with product: ApphudProduct?, fallbackName: String) {
        if let product {
            row.isHidden = false
            row.configure(product: product, planName: planName(for: product, fallback: fallbackName))
        } else {
            row.isHidden = true
            row.product = nil
        }
    }

    private static func savingsPercent(cheaper: ApphudProduct?, baseline: ApphudProduct?) -> Int? {
        guard let low = cheaper?.weeklyPriceValue, let high = baseline?.weeklyPriceValue,
              high.doubleValue > 0, low.doubleValue < high.doubleValue else { return nil }
        let saved = (high.doubleValue - low.doubleValue) / high.doubleValue * 100
        return Int(saved.rounded())
    }

    private func planName(for product: ApphudProduct, fallback: String) -> String {
        switch product.skProduct?.subscriptionPeriod?.unit {
        case .year: return "Year".localized
        case .month: return "Month".localized
        case .week: return "Week".localized
        case .day: return "Day".localized
        default: return fallback
        }
    }

    private func presentLoadFailure() {
        let alert = UIAlertController(
            title: "Couldn't load".localized,
            message: "Couldn't reach the store. Check your connection and try again.".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry".localized, style: .default) { [weak self] _ in self?.loadProducts() })
        alert.addAction(UIAlertAction(title: "Close".localized, style: .cancel))
        present(alert, animated: true)
    }

    private func presentProductsUnavailable() {
        let alert = UIAlertController(
            title: "Subscriptions unavailable".localized,
            message: "Subscription options aren't available right now. Please try again later.".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry".localized, style: .default) { [weak self] _ in self?.loadProducts() })
        alert.addAction(UIAlertAction(title: "Close".localized, style: .cancel))
        present(alert, animated: true)
    }

    private func updateSelection() {
        yearly.isSelected = selectedPlanView === yearly
        monthly.isSelected = selectedPlanView === monthly
    }

    @objc private func yearlyTapped() { selectedPlanView = yearly; updateSelection() }
    @objc private func monthlyTapped() { selectedPlanView = monthly; updateSelection() }

    // MARK: - Purchase

    @objc private func unlockTapped() {
        guard let product = selectedPlanView.product else {
            presentProductsUnavailable()
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
                    unlocked ? self.handleUnlocked() : self.presentPurchasePending()
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

    private func handleUnlocked() {
        guard !didUnlock else { return }
        didUnlock = true
        let completion = onUnlocked
        dismiss(animated: true) { completion?() }
    }

    private func presentPurchasePending() {
        let alert = UIAlertController(
            title: "Purchase pending approval".localized,
            message: "Your purchase is waiting for approval. It will unlock automatically once approved.".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }

    private func presentError(_ error: Error) {
        guard !Self.isUserCancelled(error) else { return }
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(title: "Purchase not completed".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }

    private static func isUserCancelled(_ error: Error) -> Bool {
        if let skError = error as? SKError, skError.code == .paymentCancelled { return true }
        if let storeKitError = error as? StoreKitError, case .userCancelled = storeKitError { return true }
        return false
    }

    private func presentNothingToRestore() {
        let alert = UIAlertController(
            title: "Nothing to restore".localized,
            message: "We couldn't find any active subscriptions to restore.".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }

    @objc private func closeTapped() { dismiss(animated: true) }
}
