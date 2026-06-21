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
        layer.cornerRadius = 22
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
            let titleLabel = GradientLabel(text: title, font: .systemFont(ofSize: 17, weight: .bold))
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
        let base = UIFont.systemFont(ofSize: 16, weight: .regular)
        let bold = UIFont.systemFont(ofSize: 16, weight: .semibold)
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
