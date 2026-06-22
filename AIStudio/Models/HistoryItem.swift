import Foundation

struct HistoryItem {
    let id: UUID
    let title: String
    let time: String

    init(id: UUID = UUID(), title: String, time: String) {
        self.id = id
        self.title = title
        self.time = time
    }
}

// MARK: - HistorySection
struct HistorySection {
    let title: String
    let items: [HistoryItem]
}
