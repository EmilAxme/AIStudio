import Foundation

// MARK: - VideoCatalog
// Mapped catalog the gallery consumes: display templates + whether the backend gates
// generation behind a subscription (get_templates `subscription_enabled`).
struct VideoCatalog {
    let templates: [VideoTemplate]
    let subscriptionEnabled: Bool
}

// MARK: - PixverseCatalogResponse
// GET /api/v1/get_templates/{app_id} — real PixVerse template catalog for this app.
struct PixverseCatalogResponse: Decodable {
    let templates: [RemoteVideoTemplate]
    let styles: [RemoteVideoTemplate]
    let subscriptionEnabled: Bool?
}

// MARK: - RemoteVideoTemplate
// One catalog entry. `templates` and `styles` share this shape (styles omit some fields).
struct RemoteVideoTemplate: Decodable {
    let id: Int
    let templateId: Int
    let prompt: String?
    let name: String?
    let category: String?
    let qualities: [String]?
    let duration: Int?
    let previewSmall: String?
    let previewLarge: String?
    let isActive: Bool?

    var bestPreviewURL: URL? {
        if let large = previewLarge, let url = URL(string: large) { return url }
        if let small = previewSmall, let url = URL(string: small) { return url }
        return nil
    }
}
