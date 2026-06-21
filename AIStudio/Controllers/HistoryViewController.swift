import UIKit

/// Generic history list (AI Chat / AI Video) — dated sections of `HistoryRowView`,
/// with an empty state. Reused by both modules via the factory helpers below.
final class HistoryViewController: UIViewController {
    private let navTitle: String
    private let sections: [HistorySection]
    private let emptyIcon: String
    private let emptyTitle: String
    private let emptySubtitle: String

    init(title: String, sections: [HistorySection], emptyIcon: String, emptyTitle: String, emptySubtitle: String) {
        self.navTitle = title
        self.sections = sections
        self.emptyIcon = emptyIcon
        self.emptyTitle = emptyTitle
        self.emptySubtitle = emptySubtitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background

        let header = ScreenHeaderView(title: navTitle, titleSize: 20) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        sections.isEmpty ? setupEmptyState() : setupList(below: header)
    }

    private func setupList(below header: UIView) {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 32
        stack.translatesAutoresizingMaskIntoConstraints = false

        for section in sections {
            let sectionStack = UIStackView()
            sectionStack.axis = .vertical
            sectionStack.spacing = 16

            let titleLabel = UILabel()
            titleLabel.text = section.title
            titleLabel.font = AppFont.semibold(20)
            titleLabel.textColor = .white
            sectionStack.addArrangedSubview(titleLabel)

            let rows = UIStackView()
            rows.axis = .vertical
            rows.spacing = 12
            section.items.forEach { rows.addArrangedSubview(HistoryRowView(item: $0)) }
            sectionStack.addArrangedSubview(rows)

            stack.addArrangedSubview(sectionStack)
        }

        scrollView.addSubview(stack)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func setupEmptyState() {
        let icon = GradientIconView(symbol: emptyIcon, pointSize: 44, weight: .regular)
        let title = UILabel()
        title.text = emptyTitle
        title.font = AppFont.semibold(18)
        title.textColor = .white
        let subtitle = UILabel()
        subtitle.text = emptySubtitle
        subtitle.font = AppFont.regular(14)
        subtitle.textColor = AppColor.secondaryText
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(20, after: icon)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Factories

    private static var mockSections: [HistorySection] {
        let line = "Hello, this is a test recording. I'm checking how well the app converts speech into text."
        let row = HistoryItem(title: line, time: "5:32 AM")
        return [
            HistorySection(title: "Today", items: [row, row]),
            HistorySection(title: "Yesterday", items: [row, row]),
            HistorySection(title: "March 4", items: [row, row])
        ]
    }

    static func chat(empty: Bool = false) -> HistoryViewController {
        HistoryViewController(
            title: "AI Chat History",
            sections: empty ? [] : mockSections,
            emptyIcon: "bubble.left.and.bubble.right",
            emptyTitle: "No chats yet",
            emptySubtitle: "Your conversations will appear here"
        )
    }

    static func video(empty: Bool = false) -> HistoryViewController {
        HistoryViewController(
            title: "AI Video History",
            sections: empty ? [] : mockSections,
            emptyIcon: "play.rectangle",
            emptyTitle: "No videos yet",
            emptySubtitle: "Your generated videos will appear here"
        )
    }
}
