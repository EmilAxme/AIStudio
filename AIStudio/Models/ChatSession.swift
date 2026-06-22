import Foundation

/// A saved AI Chat conversation. Persisted by `ChatHistoryStore` and reopened
/// from the history list. `chatID` is the backend chat id so a reopened session
/// continues the same conversation.
struct ChatSession: Codable, Identifiable {
    let id: UUID
    var chatID: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    /// Display title: the first thing the user asked.
    var title: String {
        messages.first(where: { $0.sender == .user })?.text ?? "New chat"
    }
}
