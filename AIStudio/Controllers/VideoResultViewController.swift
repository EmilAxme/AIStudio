import UIKit
import AVKit
import Photos

final class VideoResultViewController: UIViewController {
    private let request: VideoRequest
    private let videoService: VideoGenerationServicing
    private let history: VideoHistoryStore
    private let historyItemID = UUID()
    private var resultURL: URL?
    private var generationTask: Task<Void, Never>?
    private var downloadTask: Task<Void, Never>?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerStatusObserver: NSKeyValueObservation?
    private weak var playerController: AVPlayerViewController?

    private let resultImageView = UIImageView()
    private let shareButton = UIButton(type: .system)
    private let downloadButton = GradientButton(title: "Download".localized)
    private let actionsStack = UIStackView()

    private let orb = UIImageView(image: UIImage(named: "videoGenOrb"))
    private let statusTitle = UILabel()
    private let statusSubtitle = UILabel()
    private let loadingStack = UIStackView()

    private var state: ViewState = .loading { didSet { renderState(animated: true) } }

    init(request: VideoRequest, videoService: VideoGenerationServicing = AppServices.video, history: VideoHistoryStore = AppServices.videoHistory) {
        self.request = request
        self.videoService = videoService
        self.history = history
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        generationTask?.cancel()
        downloadTask?.cancel()
        teardownPlayer()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        renderState()
        generate()
    }

    // MARK: - Setup

    private func setupView() {
        let header = ScreenHeaderView(title: "Result".localized) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        resultImageView.image = request.images.first ?? UIImage(named: request.imageName)
        resultImageView.contentMode = .scaleAspectFill
        resultImageView.layer.cornerRadius = 24
        resultImageView.layer.cornerCurve = .continuous
        resultImageView.clipsToBounds = true
        resultImageView.isUserInteractionEnabled = true
        resultImageView.translatesAutoresizingMaskIntoConstraints = false
        resultImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playResult)))

        let play = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 42, weight: .medium)))
        play.tintColor = UIColor.white.withAlphaComponent(0.95)
        play.contentMode = .center
        play.layer.shadowColor = UIColor.black.cgColor
        play.layer.shadowOpacity = 0.35
        play.layer.shadowRadius = 12
        play.layer.shadowOffset = .zero
        play.translatesAutoresizingMaskIntoConstraints = false
        resultImageView.addSubview(play)

        let replace = UIControl()
        replace.backgroundColor = UIColor(white: 0.32, alpha: 0.55)
        replace.layer.cornerRadius = 20
        replace.translatesAutoresizingMaskIntoConstraints = false
        let replaceIcon = UIImageView(image: UIImage(named: "icRefresh2"))
        replaceIcon.tintColor = .white
        replaceIcon.contentMode = .scaleAspectFit
        let replaceLabel = UILabel()
        replaceLabel.text = "Replace".localized
        replaceLabel.textColor = .white
        replaceLabel.font = AppFont.medium(14)
        let replaceStack = UIStackView(arrangedSubviews: [replaceIcon, replaceLabel])
        replaceStack.axis = .horizontal
        replaceStack.spacing = 5
        replaceStack.alignment = .center
        replaceStack.isUserInteractionEnabled = false
        replaceStack.translatesAutoresizingMaskIntoConstraints = false
        replace.addSubview(replaceStack)
        replace.addTarget(self, action: #selector(replaceTapped), for: .touchUpInside)
        resultImageView.addSubview(replace)

        NSLayoutConstraint.activate([
            play.centerXAnchor.constraint(equalTo: resultImageView.centerXAnchor),
            play.centerYAnchor.constraint(equalTo: resultImageView.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 80),
            play.heightAnchor.constraint(equalToConstant: 80),

            replace.topAnchor.constraint(equalTo: resultImageView.topAnchor, constant: 12),
            replace.trailingAnchor.constraint(equalTo: resultImageView.trailingAnchor, constant: -12),
            replace.heightAnchor.constraint(equalToConstant: 40),
            replaceIcon.widthAnchor.constraint(equalToConstant: 18),
            replaceIcon.heightAnchor.constraint(equalToConstant: 18),
            replaceStack.leadingAnchor.constraint(equalTo: replace.leadingAnchor, constant: 14),
            replaceStack.trailingAnchor.constraint(equalTo: replace.trailingAnchor, constant: -14),
            replaceStack.centerYAnchor.constraint(equalTo: replace.centerYAnchor)
        ])

        shareButton.setTitle("Share".localized, for: .normal)
        shareButton.titleLabel?.font = AppFont.semibold(17)
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.backgroundColor = AppColor.surface
        shareButton.layer.cornerRadius = Layout.buttonRadius
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false

        actionsStack.axis = .horizontal
        actionsStack.distribution = .fillEqually
        actionsStack.spacing = 12
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.addArrangedSubview(shareButton)
        actionsStack.addArrangedSubview(downloadButton)

        orb.contentMode = .scaleAspectFit
        orb.translatesAutoresizingMaskIntoConstraints = false
        orb.widthAnchor.constraint(equalToConstant: 150).isActive = true
        orb.heightAnchor.constraint(equalToConstant: 210).isActive = true

        statusTitle.font = AppFont.semibold(18)
        statusTitle.textColor = .white
        statusTitle.textAlignment = .center
        statusSubtitle.font = AppFont.regular(14)
        statusSubtitle.textColor = AppColor.secondaryText
        statusSubtitle.textAlignment = .center
        statusSubtitle.numberOfLines = 0

        loadingStack.axis = .vertical
        loadingStack.alignment = .center
        loadingStack.spacing = 10
        loadingStack.setCustomSpacing(28, after: orb)
        loadingStack.translatesAutoresizingMaskIntoConstraints = false
        loadingStack.addArrangedSubview(orb)
        loadingStack.addArrangedSubview(statusTitle)
        loadingStack.addArrangedSubview(statusSubtitle)

        view.addSubview(resultImageView)
        view.addSubview(actionsStack)
        view.addSubview(loadingStack)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            resultImageView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            resultImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            resultImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            resultImageView.bottomAnchor.constraint(equalTo: actionsStack.topAnchor, constant: -20),

            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            actionsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            actionsStack.heightAnchor.constraint(equalToConstant: 52),

            loadingStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            loadingStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])

        shareButton.addAction(UIAction { [weak self] _ in self?.presentShareSheet() }, for: .touchUpInside)
        downloadButton.addAction(UIAction { [weak self] _ in self?.saveResultToGallery() }, for: .touchUpInside)
    }

    @objc private func replaceTapped() {
        generate()
    }

    // MARK: - Generation

    private func generate() {
        generationTask?.cancel()
        downloadTask?.cancel()
        resultURL = nil
        state = .loading

        let image = request.images.first
        let prompt = request.prompt
        let aspectRatio = request.aspectRatio
        let quality = request.quality

        generationTask = Task { [weak self] in
            guard let self else { return }
            let imageData = await Task.detached { image?.jpegData(compressionQuality: 0.9) }.value
            let parameters = VideoGenerationParameters(
                prompt: prompt, imageData: imageData, aspectRatio: aspectRatio, quality: quality
            )
            do {
                let url = try await self.videoService.generate(parameters)
                try Task.checkCancellation()
                await MainActor.run {
                    self.resultURL = url
                    self.state = .success
                    self.saveToHistory(url: url)
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.state = .error(message)
                }
            }
        }
    }

    private func saveToHistory(url: URL) {
        history.save(
            id: historyItemID,
            title: request.prompt,
            templateImageName: request.imageName,
            videoURL: url,
            poster: resultImageView.image,
            createdAt: Date()
        )
    }

    @objc private func playResult() {
        guard let url = resultURL else { return }
        teardownPlayer()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.playerItem = item
        self.player = player

        playerStatusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            DispatchQueue.main.async { self?.handlePlaybackFailure(item.error) }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackFailedToEnd(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )

        let controller = AVPlayerViewController()
        controller.player = player
        playerController = controller
        present(controller, animated: true) { player.play() }
    }

    @objc private func playbackFailedToEnd(_ note: Notification) {
        let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
        DispatchQueue.main.async { [weak self] in self?.handlePlaybackFailure(error) }
    }

    private func handlePlaybackFailure(_ error: Error?) {
        guard playerItem != nil else { return }
        teardownPlayer()
        let message = (error as? LocalizedError)?.errorDescription
            ?? error?.localizedDescription
            ?? "This video can't be played right now.".localized
        let showAlert = { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "Can't play video".localized, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
            self.present(alert, animated: true)
        }
        if let controller = playerController, controller.presentingViewController != nil {
            controller.dismiss(animated: true, completion: showAlert)
        } else {
            showAlert()
        }
    }

    private func teardownPlayer() {
        playerStatusObserver?.invalidate()
        playerStatusObserver = nil
        if let item = playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: item)
        }
        player?.pause()
        player = nil
        playerItem = nil
    }

    private func renderState(animated: Bool = false) {
        guard animated else { applyState(); return }
        UIView.transition(with: view, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.applyState()
        }
    }

    private func applyState() {
        switch state {
        case .idle, .loading:
            loadingStack.isHidden = false
            resultImageView.isHidden = true
            actionsStack.isHidden = true
            statusTitle.text = "Generating...".localized
            statusTitle.textColor = .white
            statusSubtitle.text = "We're creating the best result for you".localized
            startOrbPulse()
        case .success:
            loadingStack.isHidden = true
            resultImageView.isHidden = false
            actionsStack.isHidden = false
        case .error(let message):
            loadingStack.isHidden = false
            resultImageView.isHidden = true
            actionsStack.isHidden = true
            orb.layer.removeAllAnimations()
            statusTitle.text = "Something went wrong".localized
            statusSubtitle.text = message
            addRetryIfNeeded()
        }
    }

    private func addRetryIfNeeded() {
        guard loadingStack.arrangedSubviews.count == 3 else { return }
        let retry = GradientButton(title: "Try again".localized)
        retry.translatesAutoresizingMaskIntoConstraints = false
        retry.heightAnchor.constraint(equalToConstant: 50).isActive = true
        retry.widthAnchor.constraint(equalToConstant: 200).isActive = true
        retry.addAction(UIAction { [weak self] _ in
            self?.loadingStack.arrangedSubviews.last.flatMap { $0 as? GradientButton }?.removeFromSuperview()
            self?.generate()
        }, for: .touchUpInside)
        loadingStack.setCustomSpacing(24, after: statusSubtitle)
        loadingStack.addArrangedSubview(retry)
    }

    private func startOrbPulse() {
        orb.layer.removeAllAnimations()
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.88
        pulse.toValue = 1.06
        pulse.duration = 0.9
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        orb.layer.add(pulse, forKey: "pulse")
    }

    private func presentShareSheet() {
        let items: [Any] = [resultURL as Any, resultImageView.image as Any].compactMap { $0 }
        guard !items.isEmpty else { return }
        let sheet = UIActivityViewController(activityItems: [items.first!], applicationActivities: nil)
        present(sheet, animated: true)
    }

    private func saveResultToGallery() {
        guard let url = resultURL else { return }
        downloadButton.setLoading(true)
        downloadTask?.cancel()
        downloadTask = Task.detached { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()
                let temp = FileManager.default.temporaryDirectory
                    .appendingPathComponent("aistudio-\(UUID().uuidString).mp4")
                try data.write(to: temp)
                try Task.checkCancellation()
                try await Self.saveVideoToPhotoLibrary(at: temp)
                await self?.finishSave(success: true, message: nil)
            } catch is CancellationError {
                await self?.setDownloadLoading(false)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                await self?.finishSave(success: false, message: message)
            }
        }
    }

    private static func saveVideoToPhotoLibrary(at fileURL: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw VideoSaveError.accessDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }

    @MainActor
    private func setDownloadLoading(_ loading: Bool) {
        downloadButton.setLoading(loading)
    }

    @MainActor
    private func finishSave(success: Bool, message: String?) {
        downloadButton.setLoading(false)
        presentSavedAlert(success: success, message: message)
    }

    @MainActor
    private func presentSavedAlert(success: Bool, message: String?) {
        let alert = UIAlertController(
            title: success ? "Saved".localized : "Couldn't save".localized,
            message: success
                ? "The video has been saved to your gallery.".localized
                : (message ?? "Couldn't save the video. Please try again.".localized),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alert, animated: true)
    }
}

private enum VideoSaveError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Allow photo access in Settings to save videos to your gallery.".localized
        }
    }
}
