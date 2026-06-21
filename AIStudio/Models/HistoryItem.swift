import Foundation

/// One entry in a history list (AI Chat / AI Video).
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

/// A dated group of history items ("Today", "Yesterday", …).
struct HistorySection {
    let title: String
    let items: [HistoryItem]
}
