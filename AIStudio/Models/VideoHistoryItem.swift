import Foundation

// MARK: - VideoHistoryItem
struct VideoHistoryItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let posterFileName: String?
    let templateImageName: String?
    let videoURLString: String?
    let createdAt: Date
}
