import UIKit
import AVKit

/// Generic history list (AI Chat / AI Video) - dated sections of `HistoryRowView`,
/// with an empty state. Reused by both modules via the factory helpers below.
final class HistoryViewController: UIViewController {
    private let navTitle: String
    private let sections: [HistorySection]
    private let gridImages: [UIImage]?
    private let emptyIcon: String
    private let emptyTitle: String
    private let emptySubtitle: String

    /// Invoked when a list row is tapped (chat history uses it to reopen a chat).
    var onSelectItem: ((HistoryItem) -> Void)?
    /// Invoked when a grid thumbnail is tapped (video history uses it to play).
    var onSelectGridIndex: ((Int) -> Void)?

    init(title: String, sections: [HistorySection], gridImages: [UIImage]? = nil, emptyIcon: String, emptyTitle: String, emptySubtitle: String) {
        self.navTitle = title
        self.sections = sections
        self.gridImages = gridImages
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

        if let grid = gridImages, !grid.isEmpty {
            setupGrid(below: header, images: grid)
        } else if sections.isEmpty {
            setupEmptyState()
        } else {
            setupList(below: header)
        }
    }

    /// Two-column masonry of generated thumbnails (AI Video History).
    private func setupGrid(below header: UIView, images: [UIImage]) {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let leftColumn = UIStackView()
        let rightColumn = UIStackView()
        for column in [leftColumn, rightColumn] {
            column.axis = .vertical
            column.spacing = 12
            column.distribution = .fill
        }

        // Staggered heights give the masonry feel.
        let ratios: [CGFloat] = [1.32, 1.0, 1.46, 1.12]
        for (index, image) in images.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = false
            imageView.translatesAutoresizingMaskIntoConstraints = false

            let cell = UIControl()
            cell.layer.cornerRadius = 18
            cell.clipsToBounds = true
            cell.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(imageView)
            imageView.pinToEdges(of: cell)
            imageView.heightAnchor.constraint(equalTo: cell.widthAnchor, multiplier: ratios[index % ratios.count]).isActive = true
            cell.addAction(UIAction { [weak self] _ in self?.onSelectGridIndex?(index) }, for: .touchUpInside)

            (index % 2 == 0 ? leftColumn : rightColumn).addArrangedSubview(cell)
        }

        let columns = UIStackView(arrangedSubviews: [leftColumn, rightColumn])
        columns.axis = .horizontal
        columns.spacing = 12
        columns.distribution = .fillEqually
        columns.alignment = .top
        columns.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(columns)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            columns.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            columns.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.horizontalInset),
            columns.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.horizontalInset),
            columns.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
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
            section.items.forEach { item in
                let row = HistoryRowView(item: item)
                row.addAction(UIAction { [weak self] _ in self?.onSelectItem?(item) }, for: .touchUpInside)
                rows.addArrangedSubview(row)
            }
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

    /// Groups saved chat sessions into dated sections (Today / Yesterday / date).
    private static func buildSections(from sessions: [ChatSession]) -> [HistorySection] {
        guard !sessions.isEmpty else { return [] }
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US")
        timeFormatter.dateFormat = "h:mm a"
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US")
        dayFormatter.dateFormat = "MMMM d"

        func bucket(for date: Date) -> String {
            if calendar.isDateInToday(date) { return "Today" }
            if calendar.isDateInYesterday(date) { return "Yesterday" }
            return dayFormatter.string(from: date)
        }

        var order: [String] = []
        var grouped: [String: [HistoryItem]] = [:]
        for session in sessions {   // already sorted newest-first by the store
            let key = bucket(for: session.updatedAt)
            if grouped[key] == nil { order.append(key) }
            grouped[key, default: []].append(HistoryItem(
                id: session.id,
                title: session.title,
                time: timeFormatter.string(from: session.updatedAt)
            ))
        }
        return order.map { HistorySection(title: $0, items: grouped[$0] ?? []) }
    }

    static func chat(empty: Bool = false) -> HistoryViewController {
        let store = AppServices.chatHistory
        let vc = HistoryViewController(
            title: "AI Chat History",
            sections: empty ? [] : buildSections(from: store.sessions()),
            emptyIcon: "bubble.left.and.bubble.right",
            emptyTitle: "No chats yet",
            emptySubtitle: "Your conversations will appear here"
        )
        vc.onSelectItem = { [weak vc] item in
            guard let session = store.session(id: item.id) else { return }
            vc?.navigationController?.pushViewController(ChatViewController(session: session), animated: true)
        }
        return vc
    }

    static func video(empty: Bool = false) -> HistoryViewController {
        let store = AppServices.videoHistory
        let items = empty ? [] : store.items()
        let posters = items.map { store.poster(for: $0) ?? UIImage() }
        let vc = HistoryViewController(
            title: "AI Video History",
            sections: [],
            gridImages: items.isEmpty ? nil : posters,
            emptyIcon: "play.rectangle",
            emptyTitle: "No videos yet",
            emptySubtitle: "Your generated videos will appear here"
        )
        vc.onSelectGridIndex = { [weak vc] index in
            guard items.indices.contains(index),
                  let urlString = items[index].videoURLString,
                  let url = URL(string: urlString) else { return }
            vc?.playVideo(url)
        }
        return vc
    }

    private func playVideo(_ url: URL) {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        present(controller, animated: true) { controller.player?.play() }
    }
}
