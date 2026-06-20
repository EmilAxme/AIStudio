import UIKit

final class ChatBubbleView: UIView {
    private let textLabel = UILabel()

    init(text: String) {
        super.init(frame: .zero)
        let gradient = GradientView(colors: AppColor.inputGradient)
        gradient.translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 24
        clipsToBounds = true
        addSubview(gradient)
        gradient.pinToEdges(of: self)
        textLabel.text = text
        textLabel.textColor = .white
        textLabel.font = .App.body(17)
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { nil }
}

final class AssistantMessageView: UIView {
    private let titleLabel = UILabel()
    private let textLabel = UILabel()

    init(title: String?, text: String) {
        super.init(frame: .zero)
        backgroundColor = AppColor.surface
        layer.cornerRadius = Layout.cardRadius
        titleLabel.text = title
        titleLabel.font = .App.bold(17)
        titleLabel.textColor = AppColor.lavender
        titleLabel.numberOfLines = 0
        textLabel.text = text
        textLabel.font = .App.body(16)
        textLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        textLabel.numberOfLines = 0
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubviews(titleLabel, textLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }

    required init?(coder: NSCoder) { nil }
}

final class ChatComposerView: UIView {
    let textField = UITextField()
    var onSend: ((String) -> Void)?

    private let sendButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: 0x211B22)
        layer.cornerRadius = 32
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        textField.placeholder = "How can I help you?"
        textField.font = .App.body(17)
        textField.textColor = .white
        textField.attributedPlaceholder = NSAttributedString(
            string: "How can I help you?",
            attributes: [.foregroundColor: AppColor.mutedText]
        )
        textField.returnKeyType = .send
        textField.delegate = self

        let download = iconButton(symbol: "arrow.down.to.line.compact")
        sendButton.setImage(UIImage(systemName: "mic"), for: .normal)
        sendButton.tintColor = .white
        sendButton.layer.borderWidth = 1
        sendButton.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        sendButton.layer.cornerRadius = 24
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        download.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        addSubviews(textField, download, sendButton)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: download.leadingAnchor, constant: -10),
            download.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),
            download.centerYAnchor.constraint(equalTo: centerYAnchor),
            download.widthAnchor.constraint(equalToConstant: 48),
            download.heightAnchor.constraint(equalToConstant: 48),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            sendButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 48),
            sendButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    required init?(coder: NSCoder) { nil }

    @objc private func sendTapped() {
        let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }
        textField.text = nil
        onSend?(text)
    }

    private func iconButton(symbol: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        button.layer.cornerRadius = 24
        return button
    }
}

extension ChatComposerView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}
