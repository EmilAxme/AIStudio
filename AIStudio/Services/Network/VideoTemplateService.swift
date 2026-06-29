import Foundation

// MARK: - VideoTemplateProviding
protocol VideoTemplateProviding {
    func fetchCatalog() async throws -> VideoCatalog
}

// MARK: - VideoTemplateService
// GET /api/v1/get_templates/{app_id} -> real PixVerse catalog mapped to display templates.
final class VideoTemplateService: VideoTemplateProviding {
    private let network: NetworkService
    private let userProvider: UserIdentifierProviding

    init(network: NetworkService, userProvider: UserIdentifierProviding) {
        self.network = network
        self.userProvider = userProvider
    }

    func fetchCatalog() async throws -> VideoCatalog {
        let response = try await network.send(
            CatalogEndpoint(userID: userProvider.userID),
            as: PixverseCatalogResponse.self
        )
        let mapped = response.templates.compactMap(VideoTemplate.init(remote:))
        guard !mapped.isEmpty else { throw APIError.invalidResponse }
        return VideoCatalog(templates: mapped, subscriptionEnabled: response.subscriptionEnabled ?? false)
    }

    private struct CatalogEndpoint: Endpoint {
        let userID: String
        var baseURL: URL { AppConfig.API.videoBaseURL }
        var path: String { "/api/v1/get_templates/\(AppConfig.API.applicationID)" }
        var method: HTTPMethod { .get }
        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "app_id", value: AppConfig.API.applicationID)
            ]
        }
    }
}
