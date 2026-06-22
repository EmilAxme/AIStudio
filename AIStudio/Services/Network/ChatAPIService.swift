import Foundation

/// Assistant reply from the Dola chat backend.
struct ChatReply {
    let chatID: String
    let assistantMessage: String
}

protocol ChatServicing {
    /// Sends `message` within `chatID` and returns the assistant reply.
    ///
    /// `chatID` is a client-generated UUID - the backend creates the chat on its
    /// first use and echoes the id back, so callers reuse the same id for a
    /// conversation.
    func send(message: String, chatID: String) async throws -> ChatReply
}

final class ChatAPIService: ChatServicing {
    private let network: NetworkService
    private let userProvider: UserIdentifierProviding

    init(network: NetworkService, userProvider: UserIdentifierProviding) {
        self.network = network
        self.userProvider = userProvider
    }

    func send(message: String, chatID: String) async throws -> ChatReply {
        let endpoint = ChatEndpoint.sendMessage(
            chatID: chatID,
            message: message,
            userID: userProvider.userID
        )
        let response = try await network.send(endpoint, as: SendDolaMessageResponse.self)
        return ChatReply(chatID: response.chatId, assistantMessage: response.assistantMessage)
    }

    // MARK: - Endpoints

    private enum ChatEndpoint: Endpoint {
        case sendMessage(chatID: String, message: String, userID: String)

        var baseURL: URL { AppConfig.API.chatBaseURL }

        var path: String {
            switch self {
            case .sendMessage(let chatID, _, _):
                return "/chats/\(chatID)/messages"
            }
        }

        var method: HTTPMethod { .post }

        var queryItems: [URLQueryItem] {
            switch self {
            case .sendMessage(_, _, let userID):
                return [
                    URLQueryItem(name: "user_id", value: userID),
                    URLQueryItem(name: "app_id", value: AppConfig.API.applicationID)
                ]
            }
        }

        var body: HTTPBody? {
            switch self {
            case .sendMessage(_, let message, _):
                return .json(ChatMessageRequest(message: message))
            }
        }
    }

    // MARK: - DTOs

    private struct ChatMessageRequest: Encodable {
        let message: String
    }

    private struct SendDolaMessageResponse: Decodable {
        let chatId: String
        let assistantMessage: String
    }
}
