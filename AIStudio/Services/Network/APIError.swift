import Foundation

// MARK: - APIError
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
            return "Couldn't build the request. Please try again.".localized
        case .invalidResponse:
            return "The server returned an invalid response.".localized
        case .unauthorized:
            return "Access denied. Please check authorization.".localized
        case .server(let status, let message):
            if let message, !message.isEmpty {
                return message
            }
            return String(format: "Server error (code %d). Please try again.".localized, status)
        case .decoding:
            return "Couldn't process the server response.".localized
        case .transport:
            return "No connection to the server. Check your internet and try again.".localized
        }
    }
}
