import Foundation

struct ChatReply {
    let chatID: String
    let assistantMessage: String
}

// MARK: - ChatServicing
protocol ChatServicing {
    func send(message: String, chatID: String) async throws -> ChatReply
}

// MARK: - ChatAPIService
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

    private struct ChatMessageRequest: Encodable {
        let message: String
    }

    private struct SendDolaMessageResponse: Decodable {
        let chatId: String
        let assistantMessage: String
    }
}
