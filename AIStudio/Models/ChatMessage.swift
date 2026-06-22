import Foundation

enum ChatMessageSender: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let sender: ChatMessageSender
    let text: String
    let title: String?

    init(id: UUID = UUID(), sender: ChatMessageSender, text: String, title: String? = nil) {
        self.id = id
        self.sender = sender
        self.text = text
        self.title = title
    }
}
