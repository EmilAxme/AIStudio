import Foundation

// MARK: - ChatSession
struct ChatSession: Codable, Identifiable {
    let id: UUID
    var chatID: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    var title: String {
        messages.first(where: { $0.sender == .user })?.text ?? "New chat".localized
    }
}
