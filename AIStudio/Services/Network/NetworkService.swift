import Foundation
import OSLog

protocol NetworkService {
    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

// MARK: - URLSessionNetworkService
final class URLSessionNetworkService: NetworkService {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.labs.fviu", category: "network")

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.urlRequest()
        logRequest(request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        logResponse(http, data: data, url: request.url)

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        case 401, 403:
            throw APIError.unauthorized
        default:
            throw APIError.server(status: http.statusCode, message: Self.serverMessage(from: data))
        }
    }

    private static func serverMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let detail = object["detail"] as? String { return detail }
        if let items = object["detail"] as? [[String: Any]] {
            let messages = items.compactMap { $0["msg"] as? String }
            if !messages.isEmpty { return messages.joined(separator: "\n") }
        }
        return nil
    }

    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        logger.debug("[req] \(request.httpMethod ?? "?", privacy: .public) \(request.url?.absoluteString ?? "?", privacy: .public)")
        if let body = request.httpBody, let text = String(data: body, encoding: .utf8), !text.isEmpty {
            logger.debug("[req] body: \(text.prefix(500), privacy: .public)")
        }
        #endif
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data, url: URL?) {
        #if DEBUG
        logger.debug("[res] \(response.statusCode, privacy: .public) \(url?.absoluteString ?? "?", privacy: .public)")
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            logger.debug("[res] body: \(text.prefix(500), privacy: .public)")
        }
        #endif
    }
}
