import Foundation

// MARK: - AIWritingAction
enum AIWritingAction: CaseIterable {
    case improve, rewrite, fixGrammar, shorten

    var title: String {
        switch self {
        case .improve: return "Improve"
        case .rewrite: return "Rewrite"
        case .fixGrammar: return "Fix grammar"
        case .shorten: return "Shorten"
        }
    }
}

// MARK: - AiWritingProviding
protocol AiWritingProviding {
    func process(text: String, action: AIWritingAction) async throws -> String
}

// MARK: - AiWritingService
// POST /ai-writing — text assistant (improve / rewrite / fix grammar / shorten).
final class AiWritingService: AiWritingProviding {
    private let network: NetworkService
    private let userProvider: UserIdentifierProviding

    init(network: NetworkService, userProvider: UserIdentifierProviding) {
        self.network = network
        self.userProvider = userProvider
    }

    func process(text: String, action: AIWritingAction) async throws -> String {
        let request = AiWritingRequest(
            text: text,
            improve: action == .improve,
            rewrite: action == .rewrite,
            fixGrammar: action == .fixGrammar,
            shorten: action == .shorten
        )
        let response = try await network.send(
            AiWritingEndpoint(request: request, userID: userProvider.userID),
            as: AiWritingResponse.self
        )
        return response.resultText
    }

    private struct AiWritingEndpoint: Endpoint {
        let request: AiWritingRequest
        let userID: String
        var baseURL: URL { AppConfig.API.rootBaseURL }
        var path: String { "/ai-writing" }
        var method: HTTPMethod { .post }
        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "app_id", value: AppConfig.API.applicationID)
            ]
        }
        var body: HTTPBody? { .json(request) }
    }

    private struct AiWritingRequest: Encodable {
        let text: String
        let improve: Bool
        let rewrite: Bool
        let fixGrammar: Bool
        let shorten: Bool
    }

    private struct AiWritingResponse: Decodable {
        let resultText: String
    }
}
