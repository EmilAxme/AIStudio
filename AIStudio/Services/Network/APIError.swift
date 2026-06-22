import Foundation

/// Network-layer errors with user-facing messages for the UI's error states.
/// Transport and decoding stay distinct from HTTP-status failures so callers can
/// react differently if needed.
enum APIError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Couldn't build the request. Please try again."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unauthorized:
            return "Access denied. Please check authorization."
        case .server(let status, let message):
            if let message, !message.isEmpty {
                return message
            }
            return "Server error (code \(status)). Please try again."
        case .decoding:
            return "Couldn't process the server response."
        case .transport:
            return "No connection to the server. Check your internet and try again."
        }
    }
}
