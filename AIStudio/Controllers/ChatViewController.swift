import UIKit

final class ChatViewController: UIViewController {
    private let header = UIView()
    private let scrollView = UIScrollView()
    private let messagesStack = UIStackView()
    private let composer = ChatComposerView()
    private var messages: [ChatMessage] = [
        ChatMessage(
            sender: .user,
            text: "Hi! Can you help me write a short welcome email for a new employee joining our team?"
        ),
        ChatMessage(
            sender: .assistant,
            text: "Hi Alexander, welcome to the development team! We're all really looking forward to having you start next week, and we're confident you'll settle in quickly.\n\nHere are a few tips to help you get through your first week:\n\n•  Focus on getting up to speed — don't hesitate to ask questions if anything is unclear. We're used to helping new team members find their feet.\n\n•  Meet the team — we're having a short welcome meeting on Monday at 11:00 AM.\n\n•  Documentation — all the key materials are available in our internal knowledge base.",
            title: "Welcome to the team, Alexander!"
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupHeader()
        setupMessages()
        setupComposer()
        renderMessages(animated: false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupHeader() {
        header.backgroundColor = UIColor(hex: 0x130E16)
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .white
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        let iconGradient = GradientView(colors: AppColor.inputGradient)
        iconGradient.layer.cornerRadius = 20
        iconGradient.clipsToBounds = true
        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconGradient.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconGradient.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconGradient.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 23),
            icon.heightAnchor.constraint(equalToConstant: 23)
        ])

        let title = UILabel()
        title.text = "AI Chat"
        title.font = .App.title(23)
        title.textColor = .white
        let date = UILabel()
        date.text = "26.03.2026"
        date.font = .App.body(15)
        date.textColor = AppColor.mutedText
        let textStack = UIStackView(arrangedSubviews: [title, date])
        textStack.axis = .vertical
        textStack.spacing = 2

        let magic = UIButton(type: .system)
        magic.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
        magic.tintColor = .white

        view.addSubviews(header)
        header.addSubviews(back, iconGradient, textStack, magic)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 68),
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            back.centerYAnchor.constraint(equalTo: header.safeAreaLayoutGuide.centerYAnchor, constant: 22),
            back.widthAnchor.constraint(equalToConstant: 32),
            back.heightAnchor.constraint(equalToConstant: 42),
            iconGradient.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 16),
            iconGradient.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            iconGradient.widthAnchor.constraint(equalToConstant: 40),
            iconGradient.heightAnchor.constraint(equalToConstant: 40),
            textStack.leadingAnchor.constraint(equalTo: iconGradient.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: iconGradient.centerYAnchor),
            magic.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -22),
            magic.centerYAnchor.constraint(equalTo: iconGradient.centerYAnchor),
            magic.widthAnchor.constraint(equalToConstant: 38),
            magic.heightAnchor.constraint(equalToConstant: 38)
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
            composer.heightAnchor.constraint(equalToConstant: 140)
        ])
    }

    private func renderMessages(animated: Bool) {
        messagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        messages.forEach { message in
            let container = UIView()
            let content: UIView
            switch message.sender {
            case .user:
                content = ChatBubbleView(text: message.text)
                container.addSubview(content)
                content.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    content.topAnchor.constraint(equalTo: container.topAnchor),
                    content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
                ])
            case .assistant:
                content = AssistantMessageView(title: message.title, text: message.text)
                container.addSubview(content)
                content.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                    content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                    content.topAnchor.constraint(equalTo: container.topAnchor),
                    content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
                ])
            }
            messagesStack.addArrangedSubview(container)
        }
        if animated {
            UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        }
        DispatchQueue.main.async { [weak self] in self?.scrollToBottom() }
    }

    private func send(text: String) {
        messages.append(ChatMessage(sender: .user, text: text))
        renderMessages(animated: true)
        AppServices.chat.reply(to: text) { [weak self] reply in
            self?.messages.append(reply)
            self?.renderMessages(animated: true)
        }
    }

    private func scrollToBottom() {
        let offset = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
        scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }
}
