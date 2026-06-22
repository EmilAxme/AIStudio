import UIKit

final class VideoHistoryStore {
    private let key = "app.video.history"
    private let defaults: UserDefaults
    private let postersDirectory: URL

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        postersDirectory = caches.appendingPathComponent("VideoHistory", isDirectory: true)
        try? FileManager.default.createDirectory(at: postersDirectory, withIntermediateDirectories: true)
    }

    func items() -> [VideoHistoryItem] {
        guard let data = defaults.data(forKey: key),
              let stored = try? JSONDecoder().decode([VideoHistoryItem].self, from: data) else {
            return []
        }
        return stored.sorted { $0.createdAt > $1.createdAt }
    }

    func save(id: UUID, title: String, templateImageName: String?, videoURL: URL?, poster: UIImage?, createdAt: Date) {
        var posterFileName: String?
        if let poster, let jpeg = poster.jpegData(compressionQuality: 0.8) {
            let name = "\(id.uuidString).jpg"
            try? jpeg.write(to: postersDirectory.appendingPathComponent(name))
            posterFileName = name
        }
        let item = VideoHistoryItem(
            id: id,
            title: title,
            posterFileName: posterFileName,
            templateImageName: templateImageName,
            videoURLString: videoURL?.absoluteString,
            createdAt: createdAt
        )
        var all = items()
        if let index = all.firstIndex(where: { $0.id == id }) {
            all[index] = item
        } else {
            all.append(item)
        }
        guard let data = try? JSONEncoder().encode(all) else { return }
        defaults.set(data, forKey: key)
    }

    func poster(for item: VideoHistoryItem) -> UIImage? {
        if let name = item.posterFileName,
           let image = UIImage(contentsOfFile: postersDirectory.appendingPathComponent(name).path) {
            return image
        }
        if let asset = item.templateImageName {
            return UIImage(named: asset)
        }
        return nil
    }
}
