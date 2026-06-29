import UIKit
import AVFoundation

final class VoiceChatViewController: UIViewController {
    private let chatID: String
    private let personaID: Int?
    private let personaTitle: String?
    private let chatService: ChatServicing

    private var voiceSession: RealtimeVoiceSession?
    private var realtimeSessionID: String?
    private var setupTask: Task<Void, Never>?
    private var isMuted = false

    private let orb = UIImageView(image: UIImage(named: "videoGenOrb"))
    private let statusLabel = UILabel()
    private let transcriptLabel = UILabel()
    private let muteButton = UIButton(type: .system)

    init(chatID: String, personaID: Int?, personaTitle: String?, chatService: ChatServicing = AppServices.chat) {
        self.chatID = chatID
        self.personaID = personaID
        self.personaTitle = personaTitle
        self.chatService = chatService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    deinit { setupTask?.cancel() }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if voiceSession == nil { requestMicAndStart() }
    }

    // MARK: - Setup

    private func setupView() {
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = .white
        close.translatesAutoresizingMaskIntoConstraints = false
        close.addTarget(self, action: #selector(endTapped), for: .touchUpInside)

        let title = UILabel()
        title.text = personaTitle ?? "Voice chat"
        title.font = AppFont.semibold(18)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false

        orb.contentMode = .scaleAspectFit
        orb.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.text = "Connecting..."
        statusLabel.font = AppFont.medium(16)
        statusLabel.textColor = AppColor.secondaryText
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        transcriptLabel.font = AppFont.regular(15)
        transcriptLabel.textColor = .white
        transcriptLabel.textAlignment = .center
        transcriptLabel.numberOfLines = 4
        transcriptLabel.translatesAutoresizingMaskIntoConstraints = false

        muteButton.setTitle("Mute", for: .normal)
        muteButton.titleLabel?.font = AppFont.semibold(16)
        muteButton.setTitleColor(.white, for: .normal)
        muteButton.backgroundColor = AppColor.surface
        muteButton.layer.cornerRadius = 28
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)

        let endButton = GradientButton(title: "End")
        endButton.translatesAutoresizingMaskIntoConstraints = false
        endButton.addTarget(self, action: #selector(endTapped), for: .touchUpInside)

        let controls = UIStackView(arrangedSubviews: [muteButton, endButton])
        controls.axis = .horizontal
        controls.distribution = .fillEqually
        controls.spacing = 12
        controls.translatesAutoresizingMaskIntoConstraints = false

        view.addSubviews(close, title, orb, statusLabel, transcriptLabel, controls)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            close.widthAnchor.constraint(equalToConstant: 34),
            close.heightAnchor.constraint(equalToConstant: 34),
            title.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            orb.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orb.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            orb.widthAnchor.constraint(equalToConstant: 170),
            orb.heightAnchor.constraint(equalToConstant: 238),

            statusLabel.topAnchor.constraint(equalTo: orb.bottomAnchor, constant: 24),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            transcriptLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            transcriptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            transcriptLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            controls.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            controls.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            controls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            controls.heightAnchor.constraint(equalToConstant: 56)
        ])
        pulseOrb(speed: 1.4)
    }

    // MARK: - Session

    private func requestMicAndStart() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted { self.startSession() }
                else { self.showError("Microphone access is needed for voice chat. Enable it in Settings.") }
            }
        }
    }

    private func startSession() {
        setupTask = Task { [weak self] in
            guard let self else { return }
            do {
                let credentials = try await self.chatService.createRealtimeSession(
                    chatID: self.chatID, personaID: self.personaID, voice: nil)
                if Task.isCancelled { return }
                await MainActor.run { self.runVoice(with: credentials) }
            } catch {
                await MainActor.run {
                    self.showError((error as? LocalizedError)?.errorDescription ?? "Couldn't start the voice session.")
                }
            }
        }
    }

    private func runVoice(with credentials: DolaRealtimeSession) {
        realtimeSessionID = credentials.sessionId
        let session = RealtimeVoiceSession(credentials: credentials, instructions: nil)
        session.onStateChange = { [weak self] state in self?.handleState(state) }
        session.onUserTranscript = { [weak self] text in self?.appendTranscript("You: \(text)") }
        session.onAssistantTranscript = { [weak self] text in self?.appendTranscript(text) }
        session.onError = { [weak self] message in self?.showError(message) }
        voiceSession = session
        session.start()
    }

    private func handleState(_ state: RealtimeVoiceSession.State) {
        switch state {
        case .connecting: statusLabel.text = "Connecting..."; pulseOrb(speed: 1.4)
        case .listening: statusLabel.text = isMuted ? "Muted" : "Listening..."; pulseOrb(speed: 1.1)
        case .speaking: statusLabel.text = "Speaking..."; pulseOrb(speed: 0.6)
        case .ended: statusLabel.text = "Ended"
        case .failed: break
        }
    }

    private func appendTranscript(_ line: String) {
        transcriptLabel.text = line
    }

    private func showError(_ message: String) {
        orb.layer.removeAllAnimations()
        statusLabel.text = message
        statusLabel.textColor = AppColor.secondaryText
    }

    @objc private func toggleMute() {
        isMuted.toggle()
        voiceSession?.setMuted(isMuted)
        muteButton.setTitle(isMuted ? "Unmute" : "Mute", for: .normal)
        if isMuted { statusLabel.text = "Muted" }
    }

    @objc private func endTapped() {
        setupTask?.cancel()
        if let result = voiceSession?.stop(), !result.turns.isEmpty, let sessionID = realtimeSessionID {
            let chatID = chatID
            let service = chatService
            Task.detached {
                try? await service.completeRealtimeSession(
                    chatID: chatID, sessionID: sessionID, durationSeconds: result.duration, turns: result.turns)
            }
        }
        dismiss(animated: true)
    }

    private func pulseOrb(speed: Double) {
        orb.layer.removeAllAnimations()
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.9
        pulse.toValue = 1.08
        pulse.duration = speed
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        orb.layer.add(pulse, forKey: "pulse")
    }
}
