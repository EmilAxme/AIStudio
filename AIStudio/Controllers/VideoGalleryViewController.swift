import UIKit

final class VideoGalleryViewController: UIViewController {
    private let categories = ["Popular", "Funny", "Sad", "Trends", "Dreamy"]
    private var selectedCategory = "Popular"
    private let chipScroll = UIScrollView()
    private let chipStack = UIStackView()

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let width = ((collectionView.bounds.width - Layout.horizontalInset * 2 - 14) / 2).rounded(.down)
        let size = CGSize(width: width, height: (width * 1.35).rounded())
        if layout.itemSize != size {
            layout.itemSize = size
            layout.invalidateLayout()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupNavBar() -> NSLayoutYAxisAnchor {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .white
        back.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold), forImageIn: .normal)
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        let avatar = GradientView(colors: AppColor.inputGradient)
        avatar.layer.cornerRadius = 14
        avatar.clipsToBounds = true
        let avatarIcon = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
        avatarIcon.tintColor = .white
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(avatarIcon)

        let title = UILabel()
        title.text = "AI Video"
        title.textColor = .white
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        let titleStack = UIStackView(arrangedSubviews: [avatar, title])
        titleStack.spacing = 8
        titleStack.alignment = .center

        let refresh = UIButton(type: .system)
        refresh.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
        refresh.tintColor = .white
        refresh.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .regular), forImageIn: .normal)
        refresh.addTarget(self, action: #selector(showPhotosPermission), for: .touchUpInside)

        view.addSubviews(back, titleStack, refresh)
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
            titleStack.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 6),
            titleStack.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            refresh.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            refresh.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            refresh.widthAnchor.constraint(equalToConstant: 34),
            refresh.heightAnchor.constraint(equalToConstant: 34)
        ])
        return back.bottomAnchor
    }

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
        categories.forEach { chipStack.addArrangedSubview(makeChip(title: $0)) }
        return chipScroll.bottomAnchor
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
        label.font = .systemFont(ofSize: 15, weight: .medium)
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

    private func selectCategory(_ category: String) {
        selectedCategory = category
        chipStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        categories.forEach { chipStack.addArrangedSubview(makeChip(title: $0)) }
    }

    @objc private func showPhotosPermission() {
        let alert = UIAlertController(
            title: "Allow access to photos?",
            message: "To upload an image, the app needs access to your photo gallery.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Allow", style: .default))
        present(alert, animated: true)
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }
}

extension VideoGalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 12 }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoTemplateCell.reuseIdentifier, for: indexPath) as! VideoTemplateCell
        cell.configure(image: UIImage(named: "AstroGirl"), title: "Title")
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController(VideoCreateViewController(), animated: true)
    }
}
