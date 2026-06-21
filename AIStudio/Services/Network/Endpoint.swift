import Foundation

/// Describes a single backend request. Concrete endpoints (declared privately
/// inside each domain service) provide the pieces; `urlRequest()` assembles the
/// `URLRequest`, including the shared `Authorization` header.
protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var body: HTTPBody? { get }
}

extension Endpoint {
    var queryItems: [URLQueryItem] { [] }
    var headers: [String: String] { [:] }
    var body: HTTPBody? { nil }

    func urlRequest() throws -> URLRequest {
        // Append `path` to `baseURL` preserving the base's own path component
        // (e.g. `…/dola` + `/chats/x/messages`).
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidRequest
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw APIError.invalidRequest }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        // Every request carries the bearer token (single source: AppConfig).
        request.setValue("Bearer \(AppConfig.API.bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body {
            request.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = try body.encoded()
        }
        return request
    }
}
