import UIKit

final class ChatViewController: UIViewController {
    private let header = UIView()
    private let scrollView = UIScrollView()
    private let messagesStack = UIStackView()
    private let composer = ChatComposerView()
    private let emptyStateView = ChatEmptyStateView()
    private var messages: [ChatMessage]

    private let chatService: ChatServicing
    /// Client-generated chat id; the backend creates the chat on first send and
    /// echoes it back, so the whole conversation reuses this id.
    private var chatID = UUID().uuidString
    /// Pending assistant reply: .loading shows the typing bubble, .error shows the
    /// error bubble, .idle/.success show neither. While loading, the composer's
    /// send action is disabled so a rapid double-send can't orphan a message.
    private var replyState: ViewState = .idle {
        didSet { composer.isSendEnabled = (replyState != .loading) }
    }
    private var lastUserText: String?
    private var replyTask: Task<Void, Never>?

    /// How many `messages` are already materialized in `messagesStack`. The list
    /// only grows by appends, so we add the delta instead of rebuilding the stack
    /// (a full teardown made every bubble re-inflate from the corner on each send).
    private var renderedMessageCount = 0
    /// The trailing typing/error bubble, if shown (replaced in place, not stacked).
    private weak var statusView: UIView?

    init(startEmpty: Bool = false, chatService: ChatServicing = AppServices.chat) {
        self.chatService = chatService
        messages = startEmpty ? [] : ChatViewController.seedMessages
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    deinit { replyTask?.cancel() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupHeader()
        setupComposer()
        setupMessages()
        setupEmptyState()
        renderMessages(animated: false)
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    #if DEBUG
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaults.standard.bool(forKey: "COMPOSER_DEMO") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.composer.runSendTransitionDemo()
            }
        }
        // Integration self-test: auto-send one message to exercise the live API.
        if UserDefaults.standard.bool(forKey: "SELFTEST_CHAT") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.send(text: "Test message")
            }
        }
        // Snapshot helper: hold the typing indicator on screen.
        if UserDefaults.standard.bool(forKey: "TYPING_DEMO") {
            replyState = .loading
            renderMessages(animated: false)
        }
    }
    #endif

    private func setupHeader() {
        header.backgroundColor = UIColor(hex: 0x130E16)
        let back = UIButton(type: .system)
        back.setImage(UIImage(named: "icArrow"), for: .normal)
        back.tintColor = .white
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        let iconGradient = GradientView(colors: AppColor.inputGradient, startPoint: CGPoint(x: 0, y: 0.2), endPoint: CGPoint(x: 1, y: 0.9))
        iconGradient.layer.cornerRadius = 15
        iconGradient.clipsToBounds = true
        let icon = UIImageView(image: UIImage(named: "icGenerate"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconGradient.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconGradient.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconGradient.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16)
        ])

        let title = UILabel()
        title.text = "AI Chat"
        title.font = AppFont.font(17, .semibold)
        title.textColor = .white
        let date = UILabel()
        date.text = "26.03.2026"
        date.font = AppFont.font(12, .regular)
        date.textColor = AppColor.secondaryText
        let textStack = UIStackView(arrangedSubviews: [title, date])
        textStack.axis = .vertical
        textStack.spacing = 1

        let magic = UIButton(type: .system)
        magic.setImage(UIImage(named: "icUnion"), for: .normal)
        magic.tintColor = .white
        magic.addTarget(self, action: #selector(showHistory), for: .touchUpInside)

        view.addSubviews(header)
        header.addSubviews(back, iconGradient, textStack, magic)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            back.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
            back.widthAnchor.constraint(equalToConstant: 34),
            back.heightAnchor.constraint(equalToConstant: 34),
            iconGradient.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 6),
            iconGradient.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            iconGradient.widthAnchor.constraint(equalToConstant: 30),
            iconGradient.heightAnchor.constraint(equalToConstant: 30),
            textStack.leadingAnchor.constraint(equalTo: iconGradient.trailingAnchor, constant: 8),
            textStack.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            magic.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            magic.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            magic.widthAnchor.constraint(equalToConstant: 34),
            magic.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    private func setupMessages() {
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        let content = UIView()
        messagesStack.axis = .vertical
        messagesStack.spacing = 24
        messagesStack.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(messagesStack)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: composer.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            messagesStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Layout.horizontalInset),
            messagesStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Layout.horizontalInset),
            messagesStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            messagesStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: 24)
        ])
    }

    private func setupComposer() {
        composer.translatesAutoresizingMaskIntoConstraints = false
        composer.onSend = { [weak self] text in self?.send(text: text) }
        view.addSubview(composer)
        NSLayoutConstraint.activate([
            composer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Bottom extends under the home indicator (covered by the bar).
            composer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            // The 88pt bar sits just above the keyboard. `keyboardLayoutGuide` tracks
            // the keyboard automatically and, when it's hidden, aligns to the bottom
            // safe area - so the resting position matches the Figma exactly, and the
            // bar (and the messages above it) rise with the keyboard.
            composer.topAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -ChatComposerView.barHeight)
        ])
    }

    private func renderMessages(animated: Bool) {
        let isAwaiting = replyState == .loading
        let errorText: String? = { if case .error(let m) = replyState { return m } else { return nil } }()
        let hasContent = !messages.isEmpty || isAwaiting || errorText != nil
        emptyStateView.isHidden = hasContent
        scrollView.isHidden = !hasContent

        // Drop the trailing typing/error bubble so any new messages append in order.
        statusView?.removeFromSuperview()
        statusView = nil

        // Append only the messages not yet on screen; existing bubbles stay put.
        while renderedMessageCount < messages.count {
            let bubble = messageBubble(for: messages[renderedMessageCount])
            messagesStack.addArrangedSubview(bubble)
            if animated { animateInsertion(of: bubble) }
            renderedMessageCount += 1
        }

        // Re-attach the trailing status bubble (typing while loading, error on failure).
        if isAwaiting {
            let typing = assistantAligned(TypingIndicatorView())
            messagesStack.addArrangedSubview(typing)
            statusView = typing
            if animated { animateInsertion(of: typing) }
        } else if let errorText {
            let bubble = ChatErrorBubbleView(message: errorText)
            bubble.onRetry = { [weak self] in self?.retryLastMessage() }
            let wrapped = assistantAligned(bubble)
            messagesStack.addArrangedSubview(wrapped)
            statusView = wrapped
            if animated { animateInsertion(of: wrapped) }
        }

        scrollToBottom(animated: animated)
    }

    private func messageBubble(for message: ChatMessage) -> UIView {
        switch message.sender {
        case .user:
            return userAligned(ChatBubbleView(text: message.text))
        case .assistant:
            return assistantAligned(AssistantMessageView(title: message.title, text: message.text))
        }
    }

    /// Fades and slides in only the newly inserted bubble; the rest of the
    /// conversation is left untouched (no full-stack relayout).
    private func animateInsertion(of bubble: UIView) {
        bubble.alpha = 0
        bubble.transform = CGAffineTransform(translationX: 0, y: 10)
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            bubble.alpha = 1
            bubble.transform = .identity
        }
    }

    /// User bubble: hugs the trailing edge, leaving a gap on the left.
    private func userAligned(_ content: UIView) -> UIView {
        let container = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 48),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    /// Assistant content: inset 12pt on both sides (matches the reference).
    private func assistantAligned(_ content: UIView) -> UIView {
        let container = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func send(text: String) {
        messages.append(ChatMessage(sender: .user, text: text))
        lastUserText = text
        requestReply(for: text)
    }

    private func retryLastMessage() {
        guard let text = lastUserText else { return }
        requestReply(for: text)
    }

    /// Sends `text` to the live API, driving the loading -> success/error states.
    private func requestReply(for text: String) {
        replyTask?.cancel()
        replyState = .loading
        renderMessages(animated: true)

        replyTask = Task { [weak self] in
            guard let self else { return }
            do {
                let reply = try await self.chatService.send(message: text, chatID: self.chatID)
                try Task.checkCancellation()
                await MainActor.run {
                    self.chatID = reply.chatID
                    self.replyState = .idle
                    self.messages.append(ChatMessage(sender: .assistant, text: reply.assistantMessage))
                    self.renderMessages(animated: true)
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self.replyState = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
                    self.renderMessages(animated: true)
                }
            }
        }
    }

    private func scrollToBottom(animated: Bool) {
        // Defer so the just-added bubble is laid out and contentSize is current.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.scrollView.layoutIfNeeded()
            let offset = max(-self.scrollView.adjustedContentInset.top, self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.adjustedContentInset.bottom)
            self.scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
        }
    }

    @objc private func showHistory() {
        navigationController?.pushViewController(HistoryViewController.chat(), animated: true)
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    private static let seedMessages: [ChatMessage] = [
        ChatMessage(sender: .user, text: "Can you help me rewrite a sentence to sound clearer?"),
        ChatMessage(
            sender: .assistant,
            text: "Send me the sentence and I'll suggest a clearer version. You can also tell me the tone you want, for example formal or friendly.",
            title: "Sure"
        )
    ]
}
