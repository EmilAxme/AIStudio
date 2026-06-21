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

/// Loading state for an in-flight assistant reply: three pulsing dots inside an
/// assistant-styled bubble, matching `AssistantMessageView`'s surface.
final class TypingIndicatorView: UIView {
    private let dots = [UIView(), UIView(), UIView()]

    init() {
        super.init(frame: .zero)
        backgroundColor = AppColor.bubble
        layer.cornerRadius = Layout.cardRadius
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        dots.forEach { dot in
            dot.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            stack.addArrangedSubview(dot)
        }
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        window == nil ? stopAnimating() : startAnimating()
    }

    private func startAnimating() {
        for (index, dot) in dots.enumerated() {
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.3
            pulse.toValue = 1.0
            pulse.duration = 0.6
            pulse.beginTime = CACurrentMediaTime() + Double(index) * 0.2
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            dot.layer.add(pulse, forKey: "pulse")
        }
    }

    private func stopAnimating() {
        dots.forEach { $0.layer.removeAllAnimations() }
    }
}

/// Visible error state for a failed reply: the human message plus a tap-to-retry
/// affordance, in an assistant-aligned bubble.
final class ChatErrorBubbleView: UIControl {
    var onRetry: (() -> Void)?

    init(message: String) {
        super.init(frame: .zero)
        backgroundColor = AppColor.bubble
        layer.cornerRadius = Layout.cardRadius

        let title = UILabel()
        title.text = "Не удалось получить ответ"
        title.font = AppFont.semibold(15)
        title.textColor = UIColor(hex: 0xEB5B92)

        let body = UILabel()
        body.text = message
        body.font = AppFont.regular(14)
        body.textColor = UIColor.white.withAlphaComponent(0.82)
        body.numberOfLines = 0

        let retry = UILabel()
        retry.text = "Нажмите, чтобы повторить"
        retry.font = AppFont.medium(13)
        retry.textColor = AppColor.secondaryText

        let stack = UIStackView(arrangedSubviews: [title, body, retry])
        stack.axis = .vertical
        stack.spacing = 6
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { nil }

    @objc private func retryTapped() { onRetry?() }
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
    /// Height of the visible input row above the home indicator (Figma: 88pt @ 844).
    static let barHeight: CGFloat = 88

    let textField = UITextField()
    var onSend: ((String) -> Void)?

    /// Trailing action: an outlined mic while empty that morphs into a gradient
    /// paper-plane Send the moment there is text. The mic shrinks out, the gradient
    /// circle springs in and the plane flies up into place; clearing the field reverses it.
    private let actionButton = UIControl()
    private let actionRing = UIView()
    private let actionGradient = GradientView(
        colors: AppColor.inputGradient,
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
    )
    private let micIcon = UIImageView(image: UIImage(named: "icMic"))
    private let sendIcon = UIImageView(image: UIImage(named: "icSend"))
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    private var isSendState = false

    /// Resting transform for the inactive icon: nudged toward the lower-left and shrunk,
    /// so the plane appears to "take off" toward the upper-right on activation.
    private static let tuckedAway = CGAffineTransform(translationX: -4, y: 4).scaledBy(x: 0.5, y: 0.5)
    private static let shrunk = CGAffineTransform(scaleX: 0.5, y: 0.5)

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

        setupActionButton()

        addSubviews(textField, download, actionButton)
        // Content sits centered within the top `barHeight` band; the view itself
        // extends below to cover the home-indicator area.
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            textField.centerYAnchor.constraint(equalTo: topAnchor, constant: Self.barHeight / 2),
            textField.trailingAnchor.constraint(equalTo: download.leadingAnchor, constant: -10),
            download.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -12),
            download.centerYAnchor.constraint(equalTo: topAnchor, constant: Self.barHeight / 2),
            download.widthAnchor.constraint(equalToConstant: 48),
            download.heightAnchor.constraint(equalToConstant: 48),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            actionButton.centerYAnchor.constraint(equalTo: topAnchor, constant: Self.barHeight / 2),
            actionButton.widthAnchor.constraint(equalToConstant: 48),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        haptic.prepare()
        applySendState(false, animated: false)
    }

    required init?(coder: NSCoder) { nil }

    private func setupActionButton() {
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        actionRing.isUserInteractionEnabled = false
        actionRing.layer.cornerRadius = 24
        actionRing.layer.borderWidth = 1
        actionRing.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor

        actionGradient.isUserInteractionEnabled = false
        actionGradient.layer.cornerRadius = 24
        actionGradient.clipsToBounds = true

        for icon in [micIcon, sendIcon] {
            icon.tintColor = .white
            icon.contentMode = .scaleAspectFit
            icon.isUserInteractionEnabled = false
        }

        for sub in [actionRing, actionGradient, micIcon, sendIcon] {
            sub.translatesAutoresizingMaskIntoConstraints = false
            actionButton.addSubview(sub)
        }
        NSLayoutConstraint.activate([
            actionRing.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor),
            actionRing.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),
            actionRing.topAnchor.constraint(equalTo: actionButton.topAnchor),
            actionRing.bottomAnchor.constraint(equalTo: actionButton.bottomAnchor),
            actionGradient.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor),
            actionGradient.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),
            actionGradient.topAnchor.constraint(equalTo: actionButton.topAnchor),
            actionGradient.bottomAnchor.constraint(equalTo: actionButton.bottomAnchor),
            micIcon.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            micIcon.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            micIcon.widthAnchor.constraint(equalToConstant: 24),
            micIcon.heightAnchor.constraint(equalToConstant: 24),
            sendIcon.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            sendIcon.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            sendIcon.widthAnchor.constraint(equalToConstant: 24),
            sendIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private var hasText: Bool {
        !(textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Drives the morph between the outlined mic (empty) and the gradient Send (typing).
    private func applySendState(_ active: Bool, animated: Bool) {
        isSendState = active
        let setVisuals = {
            self.actionGradient.alpha = active ? 1 : 0
            self.actionRing.alpha = active ? 0 : 1
            self.micIcon.alpha = active ? 0 : 1
            self.sendIcon.alpha = active ? 1 : 0
        }

        guard animated else {
            setVisuals()
            actionGradient.transform = active ? .identity : Self.shrunk
            sendIcon.transform = active ? .identity : Self.tuckedAway
            micIcon.transform = active ? Self.shrunk : .identity
            return
        }

        if active {
            haptic.impactOccurred()
            actionGradient.transform = Self.shrunk
            sendIcon.transform = Self.tuckedAway
            UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.9,
                           options: [.allowUserInteraction, .beginFromCurrentState]) {
                setVisuals()
                self.actionGradient.transform = .identity
                self.sendIcon.transform = .identity
                self.micIcon.transform = Self.shrunk
            }
        } else {
            UIView.animate(withDuration: 0.26, delay: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]) {
                setVisuals()
                self.actionGradient.transform = Self.shrunk
                self.sendIcon.transform = Self.tuckedAway
                self.micIcon.transform = .identity
            }
        }
    }

    @objc private func textChanged() {
        if hasText != isSendState { applySendState(hasText, animated: true) }
    }

    @objc private func sendTapped() {
        let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }   // empty == mic; no action yet
        textField.text = nil
        applySendState(false, animated: true)
        onSend?(text)
    }

    #if DEBUG
    /// Snapshot/QA helper: drops in demo text and runs the empty→send morph so the
    /// transition can be captured on launch. Compiled out of Release builds.
    func runSendTransitionDemo(_ text: String = "Write a poem about the sea") {
        textField.text = text
        applySendState(true, animated: true)
    }
    #endif

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
