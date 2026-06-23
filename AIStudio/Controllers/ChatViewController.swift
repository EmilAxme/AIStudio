import UIKit

final class ChatViewController: UIViewController {
    private let header = UIView()
    private let scrollView = UIScrollView()
    private let messagesStack = UIStackView()
    private let composer = ChatComposerView()
    private let emptyStateView = ChatEmptyStateView()
    private var messages: [ChatMessage]

    private let chatService: ChatServicing
    private let history: ChatHistoryStore
    private let sessionID: UUID
    private let createdAt: Date
    private var userDidSend = false
    private var chatID = UUID().uuidString
    private var replyState: ViewState = .idle {
        didSet { composer.isSendEnabled = (replyState != .loading) }
    }
    private var lastUserText: String?
    private var replyTask: Task<Void, Never>?

    private var renderedMessageCount = 0
    private weak var statusView: UIView?

    init(startEmpty: Bool = false, chatService: ChatServicing = AppServices.chat, history: ChatHistoryStore = AppServices.chatHistory) {
        self.chatService = chatService
        self.history = history
        self.sessionID = UUID()
        self.createdAt = Date()
        messages = startEmpty ? [] : ChatViewController.seedMessages
        super.init(nibName: nil, bundle: nil)
    }

    init(session: ChatSession, chatService: ChatServicing = AppServices.chat, history: ChatHistoryStore = AppServices.chatHistory) {
        self.chatService = chatService
        self.history = history
        self.sessionID = session.id
        self.createdAt = session.createdAt
        self.chatID = session.chatID
        self.userDidSend = true
        messages = session.messages
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

    // MARK: - Setup

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
        date.text = Self.headerDateFormatter.string(from: createdAt)
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
            composer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            composer.topAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -ChatComposerView.barHeight)
        ])
    }

    private func renderMessages(animated: Bool) {
        let isAwaiting = replyState == .loading
        let errorText: String? = { if case .error(let m) = replyState { return m } else { return nil } }()
        let hasContent = !messages.isEmpty || isAwaiting || errorText != nil
        emptyStateView.isHidden = hasContent
        scrollView.isHidden = !hasContent

        statusView?.removeFromSuperview()
        statusView = nil

        while renderedMessageCount < messages.count {
            let bubble = messageBubble(for: messages[renderedMessageCount])
            messagesStack.addArrangedSubview(bubble)
            if animated { animateInsertion(of: bubble) }
            renderedMessageCount += 1
        }

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

    private func animateInsertion(of bubble: UIView) {
        bubble.alpha = 0
        bubble.transform = CGAffineTransform(translationX: 0, y: 10)
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            bubble.alpha = 1
            bubble.transform = .identity
        }
    }

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

    // MARK: - Sending

    private func send(text: String) {
        userDidSend = true
        messages.append(ChatMessage(sender: .user, text: text))
        lastUserText = text
        persistSession()
        requestReply(for: text)
    }

    private func persistSession() {
        guard userDidSend else { return }
        history.save(ChatSession(
            id: sessionID,
            chatID: chatID,
            messages: messages,
            createdAt: createdAt,
            updatedAt: Date()
        ))
    }

    private func retryLastMessage() {
        guard let text = lastUserText else { return }
        requestReply(for: text)
    }

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
                    self.persistSession()
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

    private static let headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    private static let seedMessages: [ChatMessage] = [
        ChatMessage(sender: .user, text: "Can you help me rewrite a sentence to sound clearer?"),
        ChatMessage(
            sender: .assistant,
            text: "Send me the sentence and I'll suggest a clearer version. You can also tell me the tone you want, for example formal or friendly.",
            title: "Sure"
        )
    ]
}
