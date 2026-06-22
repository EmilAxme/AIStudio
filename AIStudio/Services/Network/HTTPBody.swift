import Foundation

/// Request body in one of the formats the backend uses: JSON (chat),
/// x-www-form-urlencoded (text2video), multipart (image2video).
enum HTTPBody {
    case json(Encodable)
    case formURLEncoded([String: String])
    case multipart(MultipartFormData)

    var contentType: String {
        switch self {
        case .json: return "application/json"
        case .formURLEncoded: return "application/x-www-form-urlencoded"
        case .multipart(let form): return "multipart/form-data; boundary=\(form.boundary)"
        }
    }

    /// JSON uses snake_case to match the backend.
    func encoded() throws -> Data {
        switch self {
        case .json(let value):
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return try encoder.encode(value)
        case .formURLEncoded(let fields):
            let pairs = fields.map { key, value in
                "\(Self.formEscape(key))=\(Self.formEscape(value))"
            }
            return Data(pairs.joined(separator: "&").utf8)
        case .multipart(let form):
            return form.finalizedData()
        }
    }

    private static func formEscape(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}

/// Minimal `multipart/form-data` builder (text fields + one or more file parts).
struct MultipartFormData {
    let boundary: String
    private var parts = Data()

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    mutating func addField(name: String, value: String) {
        var part = "--\(boundary)\r\n"
        part += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
        part += "\(value)\r\n"
        parts.append(Data(part.utf8))
    }

    mutating func addFile(name: String, filename: String, mimeType: String, data: Data) {
        var header = "--\(boundary)\r\n"
        header += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n"
        header += "Content-Type: \(mimeType)\r\n\r\n"
        parts.append(Data(header.utf8))
        parts.append(data)
        parts.append(Data("\r\n".utf8))
    }

    func finalizedData() -> Data {
        var data = parts
        data.append(Data("--\(boundary)--\r\n".utf8))
        return data
    }
}
