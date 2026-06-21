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
    private var isAwaitingReply = false
    private var errorMessage: String?
    private var lastUserText: String?
    private var replyTask: Task<Void, Never>?

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
            composer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            // Figma: input bar is 88pt tall above the home indicator (which the bar
            // extends under). Pin the top 88pt up from the safe-area bottom.
            composer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ChatComposerView.barHeight)
        ])
    }

    private func renderMessages(animated: Bool) {
        let hasContent = !messages.isEmpty || isAwaitingReply || errorMessage != nil
        emptyStateView.isHidden = hasContent
        scrollView.isHidden = !hasContent
        messagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        messages.forEach { message in
            switch message.sender {
            case .user:
                let content = ChatBubbleView(text: message.text)
                messagesStack.addArrangedSubview(userAligned(content))
            case .assistant:
                let content = AssistantMessageView(title: message.title, text: message.text)
                messagesStack.addArrangedSubview(assistantAligned(content))
            }
        }
        if isAwaitingReply {
            messagesStack.addArrangedSubview(assistantAligned(TypingIndicatorView()))
        }
        if let errorMessage {
            let bubble = ChatErrorBubbleView(message: errorMessage)
            bubble.onRetry = { [weak self] in self?.retryLastMessage() }
            messagesStack.addArrangedSubview(assistantAligned(bubble))
        }
        if animated {
            UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        }
        DispatchQueue.main.async { [weak self] in self?.scrollToBottom() }
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

    /// Sends `text` to the live API, driving the loading → success/error states.
    private func requestReply(for text: String) {
        replyTask?.cancel()
        errorMessage = nil
        isAwaitingReply = true
        renderMessages(animated: true)

        replyTask = Task { [weak self] in
            guard let self else { return }
            do {
                let reply = try await self.chatService.send(message: text, chatID: self.chatID)
                try Task.checkCancellation()
                await MainActor.run {
                    self.chatID = reply.chatID
                    self.isAwaitingReply = false
                    self.messages.append(ChatMessage(sender: .assistant, text: reply.assistantMessage))
                    self.renderMessages(animated: true)
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self.isAwaitingReply = false
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.renderMessages(animated: true)
                }
            }
        }
    }

    private func scrollToBottom() {
        let offset = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
        scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
    }

    @objc private func showHistory() {
        navigationController?.pushViewController(HistoryViewController.chat(), animated: true)
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    private static let seedMessages: [ChatMessage] = [
        ChatMessage(
            sender: .user,
            text: "Hi! Can you help me write a short welcome email for a new employee joining our team?"
        ),
        ChatMessage(
            sender: .assistant,
            text: "Hi Alexander, welcome to the development team! We're all really looking forward to having you start next week, and we're confident you'll settle in quickly.\nHere are a few tips to help you get through your first week:\n•  **Focus on getting up to speed** — don't hesitate to ask questions if anything is unclear. We're used to helping new team members find their feet.\n•  **Meet the team** — we're having a short welcome meeting on Monday at 11:00 AM. It'll be a great chance to connect with everyone.\n•  **Documentation** — all the key materials are available in our internal knowledge base. I'll send you the link separately.",
            title: "Welcome to the team, Alexander!"
        )
    ]
}
