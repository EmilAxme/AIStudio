import UIKit
import PhotosUI

struct VideoTemplate {
    let title: String
    let imageName: String
    let requiredPhotos: Int
}

// MARK: - VideoCreateViewController
final class VideoCreateViewController: UIViewController {
    private let templates: [VideoTemplate] = [
        VideoTemplate(title: "Clay Fool", imageName: "ClayFool", requiredPhotos: 1),
        VideoTemplate(title: "Astro Duo", imageName: "AstroGirl", requiredPhotos: 2),
        VideoTemplate(title: "Dreamy", imageName: "GalleryGirl", requiredPhotos: 1)
    ]
    private var currentIndex = 0
    private var currentTemplate: VideoTemplate { templates[currentIndex] }

    private let titleLabel = UILabel()
    private let tilesStack = UIStackView()
    private let format = FormOptionView(title: "Format", value: "16:9")
    private let quality = FormOptionView(title: "Quality", value: "1080p")
    private let createButton = GradientButton(title: "Create")

    private var selectedImages: [UIImage?] = []
    private var pendingTileIndex = 0
    private var hasGrantedAccess = false
    private var pendingGatedCreate = false

    private let subscription: SubscriptionServicing

    private let formatOptions = ["16:9", "9:16", "1:1"]
    private let qualityOptions = ["540p", "720p", "1080p", "4K"]

    init(subscription: SubscriptionServicing = AppServices.subscription) {
        self.subscription = subscription
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    private let carouselInset: CGFloat = 36
    private let carouselSpacing: CGFloat = 12
    private lazy var carousel: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = carouselSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: carouselInset, bottom: 0, right: carouselInset)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast
        cv.clipsToBounds = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(CarouselImageCell.self, forCellWithReuseIdentifier: CarouselImageCell.reuseIdentifier)
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        rebuildTiles()
        updateCreateEnabled()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resumePendingCreateIfUnlocked()
    }

    private func setupView() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(named: "icArrow"), for: .normal)
        back.tintColor = .white
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        titleLabel.text = currentTemplate.title
        titleLabel.textColor = .white
        titleLabel.font = AppFont.font(17, .semibold)
        titleLabel.textAlignment = .center

        carousel.translatesAutoresizingMaskIntoConstraints = false

        tilesStack.axis = .horizontal
        tilesStack.spacing = 12
        tilesStack.alignment = .leading
        tilesStack.translatesAutoresizingMaskIntoConstraints = false

        format.addTarget(self, action: #selector(openFormat), for: .touchUpInside)
        quality.addTarget(self, action: #selector(openQuality), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        view.addSubviews(back, titleLabel, carousel, tilesStack, format, quality, createButton)
        let inset = Layout.horizontalInset
        NSLayoutConstraint.activate([
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            back.widthAnchor.constraint(equalToConstant: 34),
            back.heightAnchor.constraint(equalToConstant: 42),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: back.centerYAnchor),

            carousel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carousel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carousel.topAnchor.constraint(equalTo: back.bottomAnchor, constant: 16),
            carousel.heightAnchor.constraint(equalToConstant: 264),

            tilesStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset + 12),
            tilesStack.topAnchor.constraint(equalTo: carousel.bottomAnchor, constant: 28),
            tilesStack.heightAnchor.constraint(equalToConstant: 82),

            format.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            format.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            format.topAnchor.constraint(equalTo: tilesStack.bottomAnchor, constant: 28),
            quality.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            quality.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            quality.topAnchor.constraint(equalTo: format.bottomAnchor, constant: 10),
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            createButton.topAnchor.constraint(equalTo: quality.bottomAnchor, constant: 30),
            createButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    private var carouselItemWidth: CGFloat { view.bounds.width - 2 * carouselInset }
    private var carouselPageWidth: CGFloat { carouselItemWidth + carouselSpacing }

    private func rebuildTiles() {
        if selectedImages.count != currentTemplate.requiredPhotos {
            selectedImages = Array(repeating: nil, count: currentTemplate.requiredPhotos)
        }
        tilesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for index in 0..<currentTemplate.requiredPhotos {
            let tile = UploadTile()
            tile.translatesAutoresizingMaskIntoConstraints = false
            tile.widthAnchor.constraint(equalToConstant: 82).isActive = true
            tile.heightAnchor.constraint(equalToConstant: 82).isActive = true
            tile.setImage(selectedImages[index])
            tile.addAction(UIAction { [weak self] _ in self?.pickPhoto(forTile: index) }, for: .touchUpInside)
            tile.onRemove = { [weak self] in
                guard let self else { return }
                self.selectedImages[index] = nil
                self.rebuildTiles()
                self.updateCreateEnabled()
            }
            tilesStack.addArrangedSubview(tile)
        }
    }

    private func updateCreateEnabled() {
        createButton.isEnabled = !selectedImages.isEmpty && selectedImages.allSatisfy { $0 != nil }
    }

    private func pickPhoto(forTile index: Int) {
        pendingTileIndex = index
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if hasGrantedAccess || status == .authorized || status == .limited {
            presentPicker()
        } else {
            presentAccessAlert()
        }
    }

    private func presentAccessAlert() {
        let alert = UIAlertController(
            title: "Allow access to photos?",
            message: "To upload an image, the app needs access to your photo gallery.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Allow", style: .default) { [weak self] _ in
            guard let self else { return }
            self.hasGrantedAccess = true
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                DispatchQueue.main.async { self.presentPicker() }
            }
        })
        present(alert, animated: true)
    }

    private func presentPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func setPhoto(_ image: UIImage, forTile index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages[index] = image
        rebuildTiles()
        updateCreateEnabled()
    }

    @objc private func openFormat() { presentDropdown(for: format, options: formatOptions, showRatioIcon: true) { [weak self] in self?.format.setValue($0) } }
    @objc private func openQuality() { presentDropdown(for: quality, options: qualityOptions, showRatioIcon: false) { [weak self] in self?.quality.setValue($0) } }

    private func presentDropdown(for anchor: FormOptionView, options: [String], showRatioIcon: Bool, apply: @escaping (String) -> Void) {
        view.endEditing(true)
        anchor.setExpanded(true)
        let anchorFrame = anchor.convert(anchor.bounds, to: view)
        let overlay = DropdownOverlay(
            anchorFrame: anchorFrame,
            hostBounds: view.bounds,
            options: options,
            selected: anchor.value,
            showRatioIcon: showRatioIcon,
            onSelect: { value in apply(value); anchor.setExpanded(false) },
            onDismiss: { anchor.setExpanded(false) }
        )
        view.addSubview(overlay)
    }

    @objc private func createTapped() {
        guard createButton.isEnabled else { return }
        guard subscription.isPremium else {
            pendingGatedCreate = true
            presentPaywall { [weak self] in self?.resumePendingCreateIfUnlocked() }
            return
        }
        proceedToResult()
    }

    private func resumePendingCreateIfUnlocked() {
        guard pendingGatedCreate, subscription.isPremium, presentedViewController == nil else { return }
        pendingGatedCreate = false
        proceedToResult()
    }

    private func proceedToResult() {
        let request = VideoRequest(
            prompt: currentTemplate.title,
            imageName: currentTemplate.imageName,
            images: selectedImages.compactMap { $0 },
            aspectRatio: format.value,
            quality: quality.value
        )
        navigationController?.pushViewController(VideoResultViewController(request: request), animated: true)
    }

    private func presentPaywall(onUnlocked: @escaping () -> Void) {
        let paywall = PaywallViewController()
        paywall.onUnlocked = onUnlocked
        paywall.modalPresentationStyle = .fullScreen
        present(paywall, animated: true)
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension VideoCreateViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { templates.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselImageCell.reuseIdentifier, for: indexPath) as! CarouselImageCell
        cell.configure(image: UIImage(named: templates[indexPath.item].imageName))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: carouselItemWidth, height: collectionView.bounds.height)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let page = carouselPageWidth
        guard page > 0 else { return }
        let approx = targetContentOffset.pointee.x / page
        let index: CGFloat = velocity.x > 0 ? ceil(approx) : (velocity.x < 0 ? floor(approx) : (scrollView.contentOffset.x / page).rounded())
        let clamped = max(0, min(CGFloat(templates.count - 1), index))
        targetContentOffset.pointee.x = clamped * page
        settle(to: Int(clamped))
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        settle(to: Int((scrollView.contentOffset.x / carouselPageWidth).rounded()))
    }

    private func settle(to index: Int) {
        let clamped = max(0, min(templates.count - 1, index))
        guard clamped != currentIndex else { return }
        currentIndex = clamped
        titleLabel.text = currentTemplate.title
        rebuildTiles()
        updateCreateEnabled()
    }
}

// MARK: - PHPickerViewControllerDelegate
extension VideoCreateViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let index = pendingTileIndex
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async { self?.setPhoto(image, forTile: index) }
        }
    }
}
