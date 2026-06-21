import UIKit

final class ChatBubbleView: UIView {
    private let textLabel = UILabel()

    init(text: String) {
        super.init(frame: .zero)
        let gradient = GradientView(
            colors: AppColor.inputGradient,
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        gradient.translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 24
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        clipsToBounds = true
        addSubview(gradient)
        gradient.pinToEdges(of: self)
        textLabel.text = text
        textLabel.textColor = .white
        textLabel.font = AppFont.regular(16)
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
    private let textLabel = UILabel()

    init(title: String?, text: String) {
        super.init(frame: .zero)
        backgroundColor = AppColor.bubble
        layer.cornerRadius = Layout.cardRadius

        textLabel.attributedText = ChatText.body(from: text)
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        var topAnchorRef = topAnchor
        var topConstant: CGFloat = 18
        if let title, !title.isEmpty {
            let titleLabel = GradientLabel(text: title, font: AppFont.font(17, .bold))
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18)
            ])
            topAnchorRef = titleLabel.bottomAnchor
            topConstant = 14
        }

        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: topAnchorRef, constant: topConstant),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }

    required init?(coder: NSCoder) { nil }
}

/// Builds the assistant body from a lightweight markup: lines, `•` bullets and
/// `**bold**` lead-ins, mirroring the formatting in the reference design.
enum ChatText {
    static func body(from text: String) -> NSAttributedString {
        let base = AppFont.font(16, .regular)
        let bold = AppFont.font(16, .semibold)
        let bodyColor = UIColor.white.withAlphaComponent(0.82)
        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            let isBullet = line.hasPrefix("•")
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 4
            paragraph.paragraphSpacing = isBullet ? 6 : 9
            if isBullet {
                paragraph.headIndent = 18
            }
            var isBold = false
            for segment in line.components(separatedBy: "**") {
                if !segment.isEmpty {
                    result.append(NSAttributedString(string: segment, attributes: [
                        .font: isBold ? bold : base,
                        .foregroundColor: isBold ? UIColor.white : bodyColor,
                        .paragraphStyle: paragraph
                    ]))
                }
                isBold.toggle()
            }
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: [.paragraphStyle: paragraph]))
            }
        }
        return result
    }
}

/// Empty/start state for a new AI Chat: "Your AI assistant for anything".
final class ChatEmptyStateView: UIView {
    init() {
        super.init(frame: .zero)
        func word(_ text: String) -> UILabel {
            let l = UILabel()
            l.text = text
            l.font = AppFont.semibold(18)
            l.textColor = .white
            return l
        }
        let your = word("Your ")
        let accent = GradientLabel(text: "AI assistant", font: AppFont.semibold(18))
        accent.translatesAutoresizingMaskIntoConstraints = false
        accent.setContentHuggingPriority(.required, for: .horizontal)
        let rest = word(" for anything")
        let titleRow = UIStackView(arrangedSubviews: [your, accent, rest])
        titleRow.axis = .horizontal
        titleRow.alignment = .center

        let subtitle = UILabel()
        subtitle.text = "Ask questions, get answers, and explore ideas in seconds"
        subtitle.font = AppFont.regular(14)
        subtitle.textColor = AppColor.secondaryText
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleRow, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.pinToEdges(of: self)
        NSLayoutConstraint.activate([
            accent.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) { nil }
}

final class ChatComposerView: UIView {
    let textField = UITextField()
    var onSend: ((String) -> Void)?

    private let sendButton = UIButton(type: .system)
    private let sendGradient = GradientView(
        colors: AppColor.inputGradient,
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: 0x211B22)
        layer.cornerRadius = 32
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        textField.placeholder = "How can I help you?"
        textField.font = AppFont.regular(16)
        textField.textColor = .white
        textField.attributedPlaceholder = NSAttributedString(
            string: "How can I help you?",
            attributes: [.foregroundColor: AppColor.mutedText]
        )
        textField.returnKeyType = .send
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        let download = iconButton(imageName: "icImport")
        download.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        sendGradient.isUserInteractionEnabled = false
        sendGradient.layer.cornerRadius = 24
        sendGradient.clipsToBounds = true
        sendGradient.translatesAutoresizingMaskIntoConstraints = false
        sendButton.tintColor = .white
        sendButton.layer.cornerRadius = 24
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        addSubviews(textField, download, sendGradient, sendButton)
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
            sendButton.heightAnchor.constraint(equalToConstant: 48),
            sendGradient.trailingAnchor.constraint(equalTo: sendButton.trailingAnchor),
            sendGradient.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
            sendGradient.widthAnchor.constraint(equalToConstant: 48),
            sendGradient.heightAnchor.constraint(equalToConstant: 48)
        ])
        updateSendButton()
    }

    required init?(coder: NSCoder) { nil }

    private var hasText: Bool {
        !(textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Mic (outlined) when empty → gradient paper-plane Send when there is text.
    private func updateSendButton() {
        if hasText {
            sendGradient.isHidden = false
            sendButton.setImage(UIImage(named: "icSend"), for: .normal)
            sendButton.layer.borderWidth = 0
        } else {
            sendGradient.isHidden = true
            sendButton.setImage(UIImage(named: "icMic"), for: .normal)
            sendButton.layer.borderWidth = 1
            sendButton.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        }
    }

    @objc private func textChanged() { updateSendButton() }

    @objc private func sendTapped() {
        let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }
        textField.text = nil
        updateSendButton()
        onSend?(text)
    }

    private func iconButton(imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: imageName), for: .normal)
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
