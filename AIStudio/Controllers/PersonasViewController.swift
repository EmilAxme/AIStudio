import UIKit

final class PersonasViewController: UIViewController {
    private let chatService: ChatServicing
    private let listStack = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private var loadTask: Task<Void, Never>?

    var onSelect: ((DolaPersona) -> Void)?

    init(chatService: ChatServicing = AppServices.chat) {
        self.chatService = chatService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    deinit { loadTask?.cancel() }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background

        let header = ScreenHeaderView(title: "Choose persona", titleSize: 20) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        listStack.axis = .vertical
        listStack.spacing = 12
        listStack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(listStack)
        view.addSubview(scroll)

        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: header.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            listStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            listStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            listStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            listStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        load()
    }

    private func load() {
        spinner.startAnimating()
        loadTask = Task { [weak self] in
            guard let self else { return }
            let personas = (try? await self.chatService.personas()) ?? []
            if Task.isCancelled { return }
            await MainActor.run { self.render(personas) }
        }
    }

    private func render(_ personas: [DolaPersona]) {
        spinner.stopAnimating()
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let sorted = personas.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
        for persona in sorted {
            let row = PersonaRowView(persona: persona)
            row.addAction(UIAction { [weak self] _ in
                self?.onSelect?(persona)
            }, for: .touchUpInside)
            listStack.addArrangedSubview(row)
        }
        if sorted.isEmpty {
            let label = UILabel()
            label.text = "Personas are unavailable right now."
            label.font = AppFont.regular(15)
            label.textColor = AppColor.secondaryText
            label.textAlignment = .center
            listStack.addArrangedSubview(label)
        }
    }
}

// MARK: - PersonaRowView
final class PersonaRowView: UIControl {
    init(persona: DolaPersona) {
        super.init(frame: .zero)
        backgroundColor = AppColor.surface
        layer.cornerRadius = 18
        translatesAutoresizingMaskIntoConstraints = false

        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 28
        avatar.backgroundColor = AppColor.surfaceRaised
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.setRemoteImage(persona.avatarURL)

        let title = UILabel()
        title.text = persona.title
        title.font = AppFont.semibold(16)
        title.textColor = .white

        let tag = UILabel()
        tag.text = persona.tag
        tag.font = AppFont.medium(12)
        tag.textColor = AppColor.pink
        tag.isHidden = (persona.tag ?? "").isEmpty

        let titleRow = UIStackView(arrangedSubviews: [title, tag])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .firstBaseline

        let desc = UILabel()
        desc.text = persona.description
        desc.font = AppFont.regular(13)
        desc.textColor = AppColor.secondaryText
        desc.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleRow, desc])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubviews(avatar, textStack)
        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            avatar.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 56),
            avatar.heightAnchor.constraint(equalToConstant: 56),
            textStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            topAnchor.constraint(lessThanOrEqualTo: textStack.topAnchor, constant: -16),
            bottomAnchor.constraint(greaterThanOrEqualTo: textStack.bottomAnchor, constant: 16),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 84)
        ])
    }

    required init?(coder: NSCoder) { nil }
}
