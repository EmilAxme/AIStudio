import UIKit

final class VideoGalleryViewController: UIViewController {
    private let header = UIView()
    private let categories = ["Popular", "Funny", "Sad", "Trends", "Dreamy"]
    private var selectedCategory = "Popular"
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 18, left: Layout.horizontalInset, bottom: 20, right: Layout.horizontalInset)
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.alwaysBounceVertical = true
        collection.dataSource = self
        collection.delegate = self
        collection.register(VideoTemplateCell.self, forCellWithReuseIdentifier: VideoTemplateCell.reuseIdentifier)
        return collection
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupHeader()
        setupCategories()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let width = (collectionView.bounds.width - (Layout.horizontalInset * 2) - 12) / 2
        if layout.itemSize.width != width {
            layout.itemSize = CGSize(width: width, height: width * 1.36)
            layout.invalidateLayout()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupHeader() {
        header.backgroundColor = UIColor(hex: 0x110C14)
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .white
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        let gradient = GradientView(colors: AppColor.inputGradient)
        gradient.layer.cornerRadius = 20
        gradient.clipsToBounds = true
        let icon = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
        icon.tintColor = .white
        icon.translatesAutoresizingMaskIntoConstraints = false
        gradient.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: gradient.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: gradient.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])
        let title = UILabel()
        title.text = "AI Video"
        title.textColor = .white
        title.font = .App.title(24)

        let upload = UIButton(type: .system)
        upload.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
        upload.tintColor = .white
        upload.addTarget(self, action: #selector(showPhotosPermission), for: .touchUpInside)

        view.addSubview(header)
        header.addSubviews(back, gradient, title, upload)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 78),
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            back.centerYAnchor.constraint(equalTo: header.safeAreaLayoutGuide.centerYAnchor, constant: 22),
            back.widthAnchor.constraint(equalToConstant: 32),
            back.heightAnchor.constraint(equalToConstant: 42),
            gradient.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 16),
            gradient.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            gradient.widthAnchor.constraint(equalToConstant: 40),
            gradient.heightAnchor.constraint(equalToConstant: 40),
            title.leadingAnchor.constraint(equalTo: gradient.trailingAnchor, constant: 12),
            title.centerYAnchor.constraint(equalTo: gradient.centerYAnchor),
            upload.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -22),
            upload.centerYAnchor.constraint(equalTo: gradient.centerYAnchor),
            upload.widthAnchor.constraint(equalToConstant: 38),
            upload.heightAnchor.constraint(equalToConstant: 38)
        ])
    }

    private func setupCategories() {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        header.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -10),
            scroll.heightAnchor.constraint(equalToConstant: 44),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: Layout.horizontalInset),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -Layout.horizontalInset),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        categories.forEach { category in
            let button = UIButton(type: .system)
            button.setTitle(category, for: .normal)
            button.titleLabel?.font = .App.body(16)
            button.setTitleColor(category == selectedCategory ? .white : AppColor.secondaryText, for: .normal)
            button.backgroundColor = category == selectedCategory ? AppColor.pink : AppColor.surface
            if category == selectedCategory {
                let gradient = GradientView(colors: AppColor.inputGradient)
                gradient.isUserInteractionEnabled = false
                gradient.translatesAutoresizingMaskIntoConstraints = false
                button.insertSubview(gradient, at: 0)
                gradient.pinToEdges(of: button)
            }
            button.layer.cornerRadius = 22
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        selectedCategory = sender.currentTitle ?? "Popular"
        collectionView.reloadData()
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
        cell.configure(image: UIImage(named: "GalleryGirl"))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController(VideoCreateViewController(), animated: true)
    }
}
