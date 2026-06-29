import Foundation

struct HistoryItem {
    let id: UUID
    let title: String
    let time: String
    let remoteID: String?
    let personaID: Int?

    init(id: UUID = UUID(), title: String, time: String, remoteID: String? = nil, personaID: Int? = nil) {
        self.id = id
        self.title = title
        self.time = time
        self.remoteID = remoteID
        self.personaID = personaID
    }
}

// MARK: - HistorySection
struct HistorySection {
    let title: String
    let items: [HistoryItem]
}
