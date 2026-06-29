import Foundation

struct ChatReply {
    let chatID: String
    let assistantMessage: String
}

// MARK: - ChatServicing
protocol ChatServicing {
    func send(message: String, chatID: String, personaID: Int?) async throws -> ChatReply
    func chats() async throws -> [DolaChatSummary]
    func messages(chatID: String) async throws -> [ChatMessage]
    func personas() async throws -> [DolaPersona]
    func createRealtimeSession(chatID: String, personaID: Int?, voice: String?) async throws -> DolaRealtimeSession
    func completeRealtimeSession(chatID: String, sessionID: String, durationSeconds: Int, turns: [DolaRealtimeTurn]) async throws
}

// MARK: - ChatAPIService
final class ChatAPIService: ChatServicing {
    private let network: NetworkService
    private let userProvider: UserIdentifierProviding

    init(network: NetworkService, userProvider: UserIdentifierProviding) {
        self.network = network
        self.userProvider = userProvider
    }

    func send(message: String, chatID: String, personaID: Int?) async throws -> ChatReply {
        let endpoint = ChatEndpoint.sendMessage(
            chatID: chatID,
            message: message,
            personaID: personaID,
            userID: userProvider.userID
        )
        let response = try await network.send(endpoint, as: SendDolaMessageResponse.self)
        return ChatReply(chatID: response.chatId, assistantMessage: response.assistantMessage)
    }

    func chats() async throws -> [DolaChatSummary] {
        try await network.send(ChatEndpoint.chats(userID: userProvider.userID), as: [DolaChatSummary].self)
    }

    func messages(chatID: String) async throws -> [ChatMessage] {
        let response = try await network.send(
            ChatEndpoint.messages(chatID: chatID, userID: userProvider.userID),
            as: [DolaMessageResponse].self
        )
        return response.map(\.asChatMessage)
    }

    func personas() async throws -> [DolaPersona] {
        try await network.send(ChatEndpoint.personas(userID: userProvider.userID), as: [DolaPersona].self)
    }

    func createRealtimeSession(chatID: String, personaID: Int?, voice: String?) async throws -> DolaRealtimeSession {
        try await network.send(
            ChatEndpoint.realtimeSession(chatID: chatID, personaID: personaID, voice: voice, userID: userProvider.userID),
            as: DolaRealtimeSession.self
        )
    }

    func completeRealtimeSession(chatID: String, sessionID: String, durationSeconds: Int, turns: [DolaRealtimeTurn]) async throws {
        _ = try await network.send(
            ChatEndpoint.realtimeComplete(
                chatID: chatID,
                body: RealtimeCompleteRequest(sessionId: sessionID, durationSeconds: durationSeconds, turns: turns),
                userID: userProvider.userID
            ),
            as: EmptyDecodable.self
        )
    }

    private enum ChatEndpoint: Endpoint {
        case sendMessage(chatID: String, message: String, personaID: Int?, userID: String)
        case chats(userID: String)
        case messages(chatID: String, userID: String)
        case personas(userID: String)
        case realtimeSession(chatID: String, personaID: Int?, voice: String?, userID: String)
        case realtimeComplete(chatID: String, body: RealtimeCompleteRequest, userID: String)

        var baseURL: URL { AppConfig.API.chatBaseURL }

        var path: String {
            switch self {
            case .sendMessage(let chatID, _, _, _): return "/chats/\(chatID)/messages"
            case .chats: return "/chats"
            case .messages(let chatID, _): return "/chats/\(chatID)/messages"
            case .personas: return "/personas"
            case .realtimeSession(let chatID, _, _, _): return "/chats/\(chatID)/realtime/session"
            case .realtimeComplete(let chatID, _, _): return "/chats/\(chatID)/realtime/complete"
            }
        }

        var method: HTTPMethod {
            switch self {
            case .sendMessage, .realtimeSession, .realtimeComplete: return .post
            case .chats, .messages, .personas: return .get
            }
        }

        var queryItems: [URLQueryItem] {
            let userID: String
            switch self {
            case .sendMessage(_, _, _, let id), .chats(let id), .messages(_, let id), .personas(let id),
                 .realtimeSession(_, _, _, let id), .realtimeComplete(_, _, let id):
                userID = id
            }
            return [
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "app_id", value: AppConfig.API.applicationID)
            ]
        }

        var body: HTTPBody? {
            switch self {
            case .sendMessage(_, let message, let personaID, _):
                return .json(ChatMessageRequest(message: message, personaId: personaID))
            case .realtimeSession(_, let personaID, let voice, _):
                return .json(RealtimeSessionRequest(personaId: personaID, voice: voice))
            case .realtimeComplete(_, let body, _):
                return .json(body)
            case .chats, .messages, .personas:
                return nil
            }
        }
    }

    private struct ChatMessageRequest: Encodable {
        let message: String
        let personaId: Int?
    }

    private struct RealtimeSessionRequest: Encodable {
        let personaId: Int?
        let voice: String?
    }

    struct RealtimeCompleteRequest: Encodable {
        let sessionId: String
        let durationSeconds: Int
        let turns: [DolaRealtimeTurn]
    }

    private struct EmptyDecodable: Decodable {}

    private struct SendDolaMessageResponse: Decodable {
        let chatId: String
        let assistantMessage: String
    }
}
