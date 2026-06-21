import Foundation

/// Network-layer errors with human-readable (Russian) messages surfaced to the
/// UI's error states. Transport and decoding stay distinct from HTTP-status
/// failures so callers can react differently if needed.
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
            return "Не удалось сформировать запрос. Попробуйте позже."
        case .invalidResponse:
            return "Получен некорректный ответ сервера."
        case .unauthorized:
            return "Доступ запрещён. Проверьте авторизацию."
        case .server(let status, let message):
            if let message, !message.isEmpty {
                return message
            }
            return "Ошибка сервера (код \(status)). Попробуйте позже."
        case .decoding:
            return "Не удалось обработать ответ сервера."
        case .transport:
            return "Нет соединения с сервером. Проверьте интернет и повторите."
        }
    }
}
