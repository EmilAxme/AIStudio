import Foundation

// MARK: - DolaChatSummary
// GET /dola/chats — one row of the server-side chat list.
struct DolaChatSummary: Decodable {
    let chatId: String
    let title: String?
    let personaId: Int?
    let updatedAt: String?
    let lastMessagePreview: String?
}

// MARK: - DolaMessageResponse
// GET /dola/chats/{chat_id}/messages — one stored message.
struct DolaMessageResponse: Decodable {
    let role: String
    let content: String
    let messageSource: String?
    let createdAt: String?

    var asChatMessage: ChatMessage {
        ChatMessage(sender: role == "user" ? .user : .assistant, text: content)
    }
}

// MARK: - DolaRealtimeSession
// POST /dola/chats/{chat_id}/realtime/session — ephemeral OpenAI Realtime credentials.
struct DolaRealtimeSession: Decodable {
    let sessionId: String
    let clientSecret: String
    let expiresAt: String
    let model: String
    let voice: String
    let openaiSessionId: String
}

// MARK: - DolaRealtimeTurn
struct DolaRealtimeTurn: Codable {
    let role: String
    let content: String
}

// MARK: - DolaPersona
// GET /dola/personas — an assistant persona.
struct DolaPersona: Decodable {
    let id: Int
    let code: String
    let title: String
    let description: String?
    let avatarKey: String?
    let category: String?
    let tag: String?
    let viewsCount: String?
    let sortOrder: Int?

    var avatarURL: URL? { avatarKey.flatMap(URL.init(string:)) }
}
