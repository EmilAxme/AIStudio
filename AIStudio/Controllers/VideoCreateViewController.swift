import UIKit

final class VideoCreateViewController: UIViewController {
    private let titleLabel = UILabel()
    private let preview = UIImageView()
    private let uploadTile = UploadTile()
    private let format = FormOptionView(title: "Format", value: "16:9")
    private let quality = FormOptionView(title: "Quality", value: "1080p")
    private let createButton = GradientButton(title: "Create")
    private let stateLabel = UILabel()
    private var selectedImageName: String?
    private var shouldFailNextGeneration = false
    private var state: ViewState = .idle { didSet { renderState() } }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        setupActions()
        #if DEBUG
        if let s = UserDefaults.standard.string(forKey: "DEBUG_VC_STATE") {
            selectedImageName = "ClayFool"
            switch s {
            case "loading": state = .loading
            case "success": state = .success
            case "error": state = .error("We couldn't create this video. Please try again.")
            default: renderState()
            }
            return
        }
        #endif
        renderState()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupView() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .white
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        titleLabel.text = "Clay Fool"
        titleLabel.textColor = .white
        titleLabel.font = AppFont.font(17, .semibold)
        titleLabel.textAlignment = .center
        preview.image = UIImage(named: "AstroGirl")
        preview.contentMode = .scaleAspectFill
        preview.layer.cornerRadius = 16
        preview.clipsToBounds = true
        stateLabel.textAlignment = .center
        stateLabel.font = .App.medium(15)
        stateLabel.numberOfLines = 2

        let leftPeek = makePeek(image: "ClayFool")
        let rightPeek = makePeek(image: "ClayFool")

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubviews(back, titleLabel, content)
        content.addSubviews(leftPeek, rightPeek, preview, uploadTile, format, quality, createButton, stateLabel)
        NSLayoutConstraint.activate([
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            back.widthAnchor.constraint(equalToConstant: 34),
            back.heightAnchor.constraint(equalToConstant: 42),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            content.topAnchor.constraint(equalTo: back.bottomAnchor, constant: 18),
            preview.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            preview.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            preview.topAnchor.constraint(equalTo: content.topAnchor),
            preview.heightAnchor.constraint(equalTo: preview.widthAnchor, multiplier: 0.74),
            leftPeek.trailingAnchor.constraint(equalTo: preview.leadingAnchor, constant: -10),
            leftPeek.topAnchor.constraint(equalTo: preview.topAnchor, constant: 20),
            leftPeek.bottomAnchor.constraint(equalTo: preview.bottomAnchor, constant: -20),
            leftPeek.widthAnchor.constraint(equalToConstant: 60),
            rightPeek.leadingAnchor.constraint(equalTo: preview.trailingAnchor, constant: 10),
            rightPeek.topAnchor.constraint(equalTo: preview.topAnchor, constant: 20),
            rightPeek.bottomAnchor.constraint(equalTo: preview.bottomAnchor, constant: -20),
            rightPeek.widthAnchor.constraint(equalToConstant: 60),
            uploadTile.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            uploadTile.topAnchor.constraint(equalTo: preview.bottomAnchor, constant: 40),
            uploadTile.widthAnchor.constraint(equalToConstant: 82),
            uploadTile.heightAnchor.constraint(equalToConstant: 82),
            format.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            format.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            format.topAnchor.constraint(equalTo: uploadTile.bottomAnchor, constant: 28),
            quality.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            quality.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            quality.topAnchor.constraint(equalTo: format.bottomAnchor, constant: 10),
            createButton.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            createButton.topAnchor.constraint(equalTo: quality.bottomAnchor, constant: 34),
            createButton.heightAnchor.constraint(equalToConstant: 58),
            stateLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stateLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stateLabel.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 12)
        ])
    }

    private func makePeek(image: String) -> UIImageView {
        let peek = UIImageView(image: UIImage(named: image))
        peek.contentMode = .scaleAspectFill
        peek.layer.cornerRadius = 16
        peek.clipsToBounds = true
        peek.translatesAutoresizingMaskIntoConstraints = false
        return peek
    }

    private func setupActions() {
        uploadTile.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        let errorGesture = UILongPressGestureRecognizer(target: self, action: #selector(prepareError(_:)))
        createButton.addGestureRecognizer(errorGesture)
    }

    private func renderState() {
        switch state {
        case .idle:
            let isReady = selectedImageName != nil
            preview.image = UIImage(named: selectedImageName ?? "AstroGirl")
            createButton.isEnabled = isReady
            createButton.setTitle("Create", for: .normal)
            createButton.setLoading(false)
            stateLabel.text = nil
            stateLabel.textColor = AppColor.secondaryText
        case .loading:
            createButton.isEnabled = true
            createButton.setLoading(true)
            uploadTile.setLoading(true)
            stateLabel.text = "Generating your video…"
            stateLabel.textColor = AppColor.lavender
        case .success:
            createButton.isEnabled = true
            createButton.setLoading(false)
            createButton.setTitle("Play video", for: .normal)
            stateLabel.text = "Your video is ready"
            stateLabel.textColor = AppColor.lavender
            uploadTile.setLoading(false)
        case .error(let message):
            createButton.isEnabled = true
            createButton.setLoading(false)
            createButton.setTitle("Try again", for: .normal)
            stateLabel.text = message
            stateLabel.textColor = AppColor.pink
            uploadTile.setLoading(false)
        }
    }

    @objc private func selectImage() {
        let alert = UIAlertController(
            title: "Allow access to photos?",
            message: "To upload an image, the app needs access to your photo gallery.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Allow", style: .default) { [weak self] _ in self?.pickMockImage() })
        present(alert, animated: true)
    }

    private func pickMockImage() {
        uploadTile.setLoading(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.selectedImageName = "ClayFool"
            self?.uploadTile.setLoading(false)
            self?.state = .idle
        }
    }

    @objc private func createTapped() {
        guard let imageName = selectedImageName else { return }
        if case .success = state { return }
        state = .loading
        let request = VideoRequest(imageName: imageName, aspectRatio: "16:9", quality: "1080p")
        AppServices.video.generate(request: request, shouldFail: shouldFailNextGeneration) { [weak self] result in
            guard let self else { return }
            self.shouldFailNextGeneration = false
            switch result {
            case .success: self.state = .success
            case .failure(let error): self.state = .error(error.localizedDescription)
            }
        }
    }

    @objc private func prepareError(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, selectedImageName != nil else { return }
        shouldFailNextGeneration = true
        createTapped()
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }
}
