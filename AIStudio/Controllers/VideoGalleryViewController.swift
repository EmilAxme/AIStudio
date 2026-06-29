import UIKit

final class VideoGalleryViewController: UIViewController {
    private let templateProvider: VideoTemplateProviding

    private var allTemplates: [VideoTemplate] = []
    private var categories: [String] = []
    private var selectedCategory = VideoTemplateGallery.popularTitle
    private var items: [VideoTemplate] = []
    private var subscriptionEnabled = false
    private var loadTask: Task<Void, Never>?

    private let chipScroll = UIScrollView()
    private let chipStack = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let creditsPill = UIView()
    private let creditsLabel = UILabel()
    private var balanceTask: Task<Void, Never>?

    init(templateProvider: VideoTemplateProviding = AppServices.videoTemplates) {
        self.templateProvider = templateProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    deinit { loadTask?.cancel(); balanceTask?.cancel() }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 14
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 36, left: Layout.horizontalInset, bottom: 24, right: Layout.horizontalInset)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.alwaysBounceVertical = true
        collection.showsVerticalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(VideoTemplateCell.self, forCellWithReuseIdentifier: VideoTemplateCell.reuseIdentifier)
        return collection
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        let navBottom = setupNavBar()
        let chipsBottom = setupChips(below: navBottom)
        setupCollection(below: chipsBottom)
        setupSpinner()
        loadTemplates()
        fetchBalance()
    }

    private func fetchBalance() {
        balanceTask = Task { [weak self] in
            guard let self, let balance = try? await AppServices.video.balance() else { return }
            if Task.isCancelled { return }
            await MainActor.run {
                self.creditsLabel.text = "\(balance)"
                self.creditsPill.isHidden = false
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let width = ((collectionView.bounds.width - Layout.horizontalInset * 2 - 14) / 2).rounded(.down)
        let size = CGSize(width: width, height: (width * 1.30).rounded())
        if layout.itemSize != size {
            layout.itemSize = size
            layout.invalidateLayout()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playVisibleCells()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseVisibleCells()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Loading

    private func loadTemplates() {
        spinner.startAnimating()
        loadTask = Task { [weak self] in
            guard let self else { return }
            let catalog: VideoCatalog
            do {
                catalog = try await self.templateProvider.fetchCatalog()
            } catch is CancellationError {
                return
            } catch {
                catalog = VideoCatalog(templates: VideoTemplateCatalog.fallback, subscriptionEnabled: false)
            }
            if Task.isCancelled { return }
            await MainActor.run { self.apply(catalog: catalog) }
        }
    }

    private func apply(catalog: VideoCatalog) {
        spinner.stopAnimating()
        subscriptionEnabled = catalog.subscriptionEnabled
        allTemplates = [VideoTemplate.blend] + catalog.templates
        categories = VideoTemplateGallery.categories(from: allTemplates)
        selectedCategory = categories.first ?? VideoTemplateGallery.popularTitle
        items = VideoTemplateGallery.items(allTemplates, in: selectedCategory)
        rebuildChips()
        collectionView.reloadData()
        playVisibleCells()
    }

    // MARK: - Nav bar

    private func setupNavBar() -> NSLayoutYAxisAnchor {
        let back = UIButton(type: .system)
        back.setImage(UIImage(named: "icArrow"), for: .normal)
        back.tintColor = .white
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        let avatar = GradientView(colors: AppColor.inputGradient)
        avatar.layer.cornerRadius = 14
        avatar.clipsToBounds = true
        let avatarIcon = UIImageView(image: UIImage(named: "icImageToImage"))
        avatarIcon.tintColor = .white
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(avatarIcon)

        let title = UILabel()
        title.text = "AI Video"
        title.textColor = .white
        title.font = AppFont.font(17, .semibold)
        let titleStack = UIStackView(arrangedSubviews: [avatar, title])
        titleStack.spacing = 8
        titleStack.alignment = .center

        let refresh = UIButton(type: .system)
        refresh.setImage(UIImage(named: "icUnion"), for: .normal)
        refresh.tintColor = .white
        refresh.addTarget(self, action: #selector(showVideoHistory), for: .touchUpInside)

        creditsPill.backgroundColor = AppColor.surface
        creditsPill.layer.cornerRadius = 14
        creditsPill.isHidden = true
        creditsPill.translatesAutoresizingMaskIntoConstraints = false
        let bolt = UIImageView(image: UIImage(systemName: "bolt.fill"))
        bolt.tintColor = AppColor.pink
        bolt.contentMode = .scaleAspectFit
        bolt.translatesAutoresizingMaskIntoConstraints = false
        creditsLabel.font = AppFont.font(13, .semibold)
        creditsLabel.textColor = .white
        creditsLabel.translatesAutoresizingMaskIntoConstraints = false
        creditsPill.addSubviews(bolt, creditsLabel)

        view.addSubviews(back, titleStack, refresh, creditsPill)
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22),
            back.widthAnchor.constraint(equalToConstant: 34),
            back.heightAnchor.constraint(equalToConstant: 34),
            avatar.widthAnchor.constraint(equalToConstant: 28),
            avatar.heightAnchor.constraint(equalToConstant: 28),
            avatarIcon.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 18),
            avatarIcon.heightAnchor.constraint(equalToConstant: 18),
            titleStack.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 6),
            titleStack.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            refresh.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            refresh.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            refresh.widthAnchor.constraint(equalToConstant: 34),
            refresh.heightAnchor.constraint(equalToConstant: 34),
            creditsPill.trailingAnchor.constraint(equalTo: refresh.leadingAnchor, constant: -8),
            creditsPill.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            creditsPill.heightAnchor.constraint(equalToConstant: 28),
            bolt.leadingAnchor.constraint(equalTo: creditsPill.leadingAnchor, constant: 10),
            bolt.centerYAnchor.constraint(equalTo: creditsPill.centerYAnchor),
            bolt.widthAnchor.constraint(equalToConstant: 11),
            bolt.heightAnchor.constraint(equalToConstant: 13),
            creditsLabel.leadingAnchor.constraint(equalTo: bolt.trailingAnchor, constant: 5),
            creditsLabel.trailingAnchor.constraint(equalTo: creditsPill.trailingAnchor, constant: -10),
            creditsLabel.centerYAnchor.constraint(equalTo: creditsPill.centerYAnchor)
        ])
        return back.bottomAnchor
    }

    // MARK: - Chips

    private func setupChips(below: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        chipScroll.showsHorizontalScrollIndicator = false
        chipScroll.translatesAutoresizingMaskIntoConstraints = false
        chipStack.axis = .horizontal
        chipStack.spacing = 10
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        chipScroll.addSubview(chipStack)
        view.addSubview(chipScroll)
        NSLayoutConstraint.activate([
            chipScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipScroll.topAnchor.constraint(equalTo: below, constant: 16),
            chipScroll.heightAnchor.constraint(equalToConstant: 34),
            chipStack.leadingAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.leadingAnchor, constant: Layout.horizontalInset),
            chipStack.trailingAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.trailingAnchor, constant: -Layout.horizontalInset),
            chipStack.topAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.topAnchor),
            chipStack.bottomAnchor.constraint(equalTo: chipScroll.contentLayoutGuide.bottomAnchor),
            chipStack.heightAnchor.constraint(equalTo: chipScroll.frameLayoutGuide.heightAnchor)
        ])
        return chipScroll.bottomAnchor
    }

    private func rebuildChips() {
        chipStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        categories.forEach { chipStack.addArrangedSubview(makeChip(title: $0)) }
    }

    private func makeChip(title: String) -> UIControl {
        let isSelected = title == selectedCategory
        let chip = UIControl()
        chip.layer.cornerRadius = 17
        chip.clipsToBounds = true
        if isSelected {
            let gradient = GradientView(colors: AppColor.inputGradient, startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
            gradient.isUserInteractionEnabled = false
            gradient.translatesAutoresizingMaskIntoConstraints = false
            chip.addSubview(gradient)
            gradient.pinToEdges(of: chip)
        } else {
            chip.backgroundColor = AppColor.surface
        }
        let label = UILabel()
        label.text = title
        label.font = AppFont.font(15, .medium)
        label.textColor = isSelected ? .white : AppColor.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(label)
        NSLayoutConstraint.activate([
            chip.heightAnchor.constraint(equalToConstant: 34),
            label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -18),
            label.centerYAnchor.constraint(equalTo: chip.centerYAnchor)
        ])
        chip.addAction(UIAction { [weak self] _ in self?.selectCategory(title) }, for: .touchUpInside)
        return chip
    }

    // MARK: - Collection / spinner

    private func setupCollection(below: NSLayoutYAxisAnchor) {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: below, constant: 12),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupSpinner() {
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func selectCategory(_ category: String) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        items = VideoTemplateGallery.items(allTemplates, in: category)
        UIView.transition(with: chipStack, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.rebuildChips()
        }
        collectionView.reloadData()
        if !items.isEmpty {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        }
        playVisibleCells()
    }

    private func playVisibleCells() {
        collectionView.visibleCells.forEach { ($0 as? VideoTemplateCell)?.play() }
    }

    private func pauseVisibleCells() {
        collectionView.visibleCells.forEach { ($0 as? VideoTemplateCell)?.pause() }
    }

    @objc private func showVideoHistory() {
        navigationController?.pushViewController(HistoryViewController.video(), animated: true)
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension VideoGalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoTemplateCell.reuseIdentifier, for: indexPath) as! VideoTemplateCell
        cell.configure(template: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoTemplateCell)?.play()
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoTemplateCell)?.pause()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController(
            VideoCreateViewController(template: items[indexPath.item], subscriptionRequired: subscriptionEnabled),
            animated: true)
    }
}
