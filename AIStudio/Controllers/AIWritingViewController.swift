import UIKit

final class AIWritingViewController: UIViewController {
    private let service: AiWritingProviding
    private var selectedAction: AIWritingAction
    private var task: Task<Void, Never>?

    private let editorView = UITextView()
    private let placeholderLabel = UILabel()
    private let chipsStack = UIStackView()
    private let processButton = GradientButton(title: "Process")
    private let resultCard = UIView()
    private let resultLabel = UILabel()

    init(initialAction: AIWritingAction = .improve, service: AiWritingProviding = AppServices.aiWriting) {
        self.selectedAction = initialAction
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    deinit { task?.cancel() }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupView()
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
    }

    private func setupView() {
        let header = ScreenHeaderView(title: "AI Writing", titleSize: 20) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let inputCard = UIView()
        inputCard.backgroundColor = AppColor.surface
        inputCard.layer.cornerRadius = 20
        inputCard.translatesAutoresizingMaskIntoConstraints = false

        editorView.backgroundColor = .clear
        editorView.textColor = .white
        editorView.font = AppFont.regular(16)
        editorView.tintColor = AppColor.pink
        editorView.delegate = self
        editorView.translatesAutoresizingMaskIntoConstraints = false
        editorView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)

        placeholderLabel.text = "Paste or type your text..."
        placeholderLabel.font = AppFont.regular(16)
        placeholderLabel.textColor = AppColor.secondaryText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        inputCard.addSubview(editorView)
        inputCard.addSubview(placeholderLabel)

        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsStack.distribution = .fillProportionally
        chipsStack.translatesAutoresizingMaskIntoConstraints = false
        rebuildChips()

        processButton.translatesAutoresizingMaskIntoConstraints = false
        processButton.addTarget(self, action: #selector(processTapped), for: .touchUpInside)

        resultCard.backgroundColor = AppColor.surface
        resultCard.layer.cornerRadius = 20
        resultCard.isHidden = true
        resultCard.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.numberOfLines = 0
        resultLabel.font = AppFont.regular(16)
        resultLabel.textColor = .white
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy", for: .normal)
        copyButton.titleLabel?.font = AppFont.semibold(14)
        copyButton.setTitleColor(AppColor.pink, for: .normal)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.addTarget(self, action: #selector(copyResult), for: .touchUpInside)
        resultCard.addSubview(resultLabel)
        resultCard.addSubview(copyButton)

        let content = UIStackView(arrangedSubviews: [inputCard, chipsStack, processButton, resultCard])
        content.axis = .vertical
        content.spacing = 16
        content.setCustomSpacing(20, after: processButton)
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: header.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),

            inputCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 170),
            editorView.topAnchor.constraint(equalTo: inputCard.topAnchor),
            editorView.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: inputCard.bottomAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: editorView.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: editorView.leadingAnchor, constant: 18),

            processButton.heightAnchor.constraint(equalToConstant: 56),

            resultLabel.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 16),
            resultLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),
            copyButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 10),
            copyButton.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),
            copyButton.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -14)
        ])
    }

    private func rebuildChips() {
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for action in AIWritingAction.allCases {
            chipsStack.addArrangedSubview(makeChip(action))
        }
    }

    private func makeChip(_ action: AIWritingAction) -> UIControl {
        let isSelected = action == selectedAction
        let chip = UIControl()
        chip.layer.cornerRadius = 16
        chip.clipsToBounds = true
        if isSelected {
            let gradient = GradientView(colors: AppColor.inputGradient, startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
            gradient.isUserInteractionEnabled = false
            gradient.translatesAutoresizingMaskIntoConstraints = false
            chip.addSubview(gradient)
            gradient.pinToEdges(of: chip)
        } else {
            chip.backgroundColor = AppColor.surface
        }
        let label = UILabel()
        label.text = action.title
        label.font = AppFont.font(13, .medium)
        label.textColor = isSelected ? .white : AppColor.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(label)
        NSLayoutConstraint.activate([
            chip.heightAnchor.constraint(equalToConstant: 32),
            label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: chip.centerYAnchor)
        ])
        chip.addAction(UIAction { [weak self] _ in
            self?.selectedAction = action
            self?.rebuildChips()
        }, for: .touchUpInside)
        return chip
    }

    @objc private func processTapped() {
        view.endEditing(true)
        let text = editorView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        processButton.setLoading(true)
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.service.process(text: text, action: self.selectedAction)
                try Task.checkCancellation()
                await MainActor.run { self.showResult(result) }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self.processButton.setLoading(false)
                    self.presentError((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
                }
            }
        }
    }

    private func showResult(_ text: String) {
        processButton.setLoading(false)
        resultLabel.text = text
        resultCard.isHidden = false
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(title: "Couldn't process text", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func copyResult() {
        UIPasteboard.general.string = resultLabel.text
    }
}

// MARK: - UITextViewDelegate
extension AIWritingViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
