import UIKit
import AVKit

/// AI Video result screen: runs the real generation (start + status polling,
/// loading orb) then shows the result with Share / Download actions. Error state
/// offers retry.
final class VideoResultViewController: UIViewController {
    private let request: VideoRequest
    private let videoService: VideoGenerationServicing
    private var resultURL: URL?
    private var generationTask: Task<Void, Never>?
    private var downloadTask: Task<Void, Never>?

    private let resultImageView = UIImageView()
    private let shareButton = UIButton(type: .system)
    private let downloadButton = GradientButton(title: "Download")
    private let actionsStack = UIStackView()

    private let orb = UIImageView(image: UIImage(named: "videoGenOrb"))
    private let statusTitle = UILabel()
    private let statusSubtitle = UILabel()
    private let loadingStack = UIStackView()

    private var state: ViewState = .loading { didSet { renderState() } }

    init(request: VideoRequest, videoService: VideoGenerationServicing = AppServices.video) {
        self.request = request
        self.videoService = videoService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        generationTask?.cancel()
        downloadTask?.cancel()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        renderState()
        generate()
    }

    private func setupView() {
        let header = ScreenHeaderView(title: "Result") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        // Poster: the user's picked photo when available, else the template image.
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

        // Replace pill: restarts generation.
        let replace = UIControl()
        replace.backgroundColor = UIColor(white: 0.32, alpha: 0.55)
        replace.layer.cornerRadius = 20
        replace.translatesAutoresizingMaskIntoConstraints = false
        let replaceIcon = UIImageView(image: UIImage(named: "icRefresh2"))
        replaceIcon.tintColor = .white
        replaceIcon.contentMode = .scaleAspectFit
        let replaceLabel = UILabel()
        replaceLabel.text = "Replace"
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

        shareButton.setTitle("Share", for: .normal)
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

        // Loading state (glossy generation orb image + text)
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

    /// Starts a real generation: posts to PixVerse, polls status to completion,
    /// then surfaces the result URL. Cancellable; drives the loading/error states.
    private func generate() {
        generationTask?.cancel()
        resultURL = nil
        state = .loading

        let parameters = VideoGenerationParameters(
            prompt: request.prompt,
            imageData: request.images.first?.jpegData(compressionQuality: 0.9),
            aspectRatio: request.aspectRatio,
            quality: request.quality
        )

        generationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await self.videoService.generate(parameters)
                try Task.checkCancellation()
                await MainActor.run {
                    self.resultURL = url
                    self.state = .success
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

    /// Plays the generated video (the real result URL) in a system player.
    @objc private func playResult() {
        guard let url = resultURL else { return }
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        present(controller, animated: true) { player.play() }
    }

    private func renderState() {
        switch state {
        case .idle, .loading:
            loadingStack.isHidden = false
            resultImageView.isHidden = true
            actionsStack.isHidden = true
            statusTitle.text = "Generating..."
            statusTitle.textColor = .white
            statusSubtitle.text = "We're creating the best result for you"
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
            statusTitle.text = "Something went wrong"
            statusSubtitle.text = message
            addRetryIfNeeded()
        }
    }

    private func addRetryIfNeeded() {
        guard loadingStack.arrangedSubviews.count == 3 else { return }
        let retry = GradientButton(title: "Try again")
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
        // Share the real generated video URL when available, else the poster image.
        let items: [Any] = [resultURL as Any, resultImageView.image as Any].compactMap { $0 }
        guard !items.isEmpty else { return }
        let sheet = UIActivityViewController(activityItems: [items.first!], applicationActivities: nil)
        present(sheet, animated: true)
    }

    /// Downloads the generated video and saves it to the photo library.
    private func saveResultToGallery() {
        guard let url = resultURL else { return }
        let downloadButton = self.downloadButton
        downloadButton.setLoading(true)
        downloadTask?.cancel()
        downloadTask = Task { [weak self] in
            defer { Task { @MainActor in downloadButton.setLoading(false) } }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()
                let temp = FileManager.default.temporaryDirectory
                    .appendingPathComponent("aistudio-\(UUID().uuidString).mp4")
                try data.write(to: temp)
                guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(temp.path) else {
                    throw VideoGenerationError.noResultURL
                }
                UISaveVideoAtPathToSavedPhotosAlbum(temp.path, nil, nil, nil)
                await self?.presentSavedAlert(success: true)
            } catch is CancellationError {
                return
            } catch {
                await self?.presentSavedAlert(success: false)
            }
        }
    }

    @MainActor
    private func presentSavedAlert(success: Bool) {
        let alert = UIAlertController(
            title: success ? "Saved" : "Couldn't save",
            message: success
                ? "The video has been saved to your gallery."
                : "Couldn't download the video. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
