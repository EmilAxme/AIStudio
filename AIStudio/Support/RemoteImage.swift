import UIKit

// MARK: - RemoteImage
// Minimal async image loader with an in-memory cache, for persona avatars.
enum RemoteImage {
    private static let cache = NSCache<NSURL, UIImage>()

    static func load(_ url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}

extension UIImageView {
    // Tags the request so a recycled image view ignores a stale late response.
    func setRemoteImage(_ url: URL?, placeholder: UIImage? = nil) {
        image = placeholder
        guard let url else { return }
        let token = UUID()
        currentRemoteImageToken = token
        Task { [weak self] in
            let loaded = await RemoteImage.load(url)
            await MainActor.run {
                guard let self, self.currentRemoteImageToken == token else { return }
                if let loaded { self.image = loaded }
            }
        }
    }

    private static var tokenKey: UInt8 = 0
    private var currentRemoteImageToken: UUID? {
        get { objc_getAssociatedObject(self, &Self.tokenKey) as? UUID }
        set { objc_setAssociatedObject(self, &Self.tokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
