import Foundation

/// The three request-body shapes this backend actually uses:
/// - JSON for Dola chat,
/// - `application/x-www-form-urlencoded` for `text2video`,
/// - `multipart/form-data` for `image2video` (mixed text fields + a file).
///
/// (The brief described a single `Encodable?` body; the live PixVerse contract
/// requires form + multipart uploads, so the body is modelled as an enum. JSON
/// still flows through a type-erased `Encodable` as requested — see `AnyEncodable`.)
enum HTTPBody {
    case json(any Encodable)
    case formURLEncoded([String: String])
    case multipart(MultipartFormData)

    var contentType: String {
        switch self {
        case .json: return "application/json"
        case .formURLEncoded: return "application/x-www-form-urlencoded"
        case .multipart(let form): return "multipart/form-data; boundary=\(form.boundary)"
        }
    }

    /// Encodes the body to `Data`. JSON uses snake_case to match the backend.
    func encoded() throws -> Data {
        switch self {
        case .json(let value):
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return try encoder.encode(AnyEncodable(value))
        case .formURLEncoded(let fields):
            let pairs = fields.map { key, value in
                "\(Self.formEscape(key))=\(Self.formEscape(value))"
            }
            return Data(pairs.joined(separator: "&").utf8)
        case .multipart(let form):
            return form.finalizedData()
        }
    }

    /// `x-www-form-urlencoded` percent-encoding (spaces become `+` is also valid,
    /// but `%20` via this allowed set is accepted by FastAPI and avoids ambiguity).
    private static func formEscape(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}

/// Type-erased `Encodable` so heterogeneous request models can be encoded via a
/// single `JSONEncoder` call (an existential `any Encodable` can't be encoded
/// directly on iOS 16).
struct AnyEncodable: Encodable {
    private let encodeTo: (Encoder) throws -> Void

    init(_ wrapped: some Encodable) {
        encodeTo = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeTo(encoder)
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
