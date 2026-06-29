import Foundation

// MARK: - VideoTemplate
// Unified display model the gallery and create screens render. Backed either by a
// real server template (templateId != nil, remote preview) or by a bundled offline
// fallback clip (previewVideoName set) used when the catalog can't be fetched.
struct VideoTemplate {
    let id: String
    let title: String
    let prompt: String
    let category: String
    let templateId: Int?          // server template_id for template2video; nil = offline fallback
    let previewURL: URL?          // remote preview (.mp4)
    let previewVideoName: String? // bundled fallback clip (without extension)
    let posterName: String?       // bundled poster / still fallback
    let requiredPhotos: Int
    let transition: Bool          // generate via transition2video (multi-photo blend)

    init(id: String, title: String, prompt: String, category: String, templateId: Int?,
         previewURL: URL?, previewVideoName: String?, posterName: String?, requiredPhotos: Int, transition: Bool = false) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.category = category
        self.templateId = templateId
        self.previewURL = previewURL
        self.previewVideoName = previewVideoName
        self.posterName = posterName
        self.requiredPhotos = requiredPhotos
        self.transition = transition
    }

    var isRemote: Bool { templateId != nil }

    // Built-in advanced mode: blends 2 photos into a transition video (transition2video).
    static let blend = VideoTemplate(
        id: "blend", title: "Blend Photos",
        prompt: "A smooth cinematic transition blending the two photos",
        category: VideoTemplateGallery.popularTitle, templateId: nil,
        previewURL: nil, previewVideoName: "tpl_astro_duo", posterName: "AstroGirl",
        requiredPhotos: 2, transition: true
    )
}

extension VideoTemplate {
    // Maps a server catalog entry. Returns nil for entries with no usable preview / id.
    init?(remote: RemoteVideoTemplate) {
        guard remote.isActive ?? true, let preview = remote.bestPreviewURL else { return nil }
        let name = remote.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = "tpl-\(remote.templateId)"
        self.title = (name?.isEmpty == false ? name! : "Template")
        self.prompt = remote.prompt ?? (name ?? "")
        self.category = remote.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "More"
        self.templateId = remote.templateId
        self.previewURL = preview
        self.previewVideoName = nil
        self.posterName = nil
        self.requiredPhotos = 1
        self.transition = false
    }
}

// MARK: - Gallery sectioning
enum VideoTemplateGallery {
    static let popularTitle = "Popular"
    private static let popularCount = 24

    // Chip titles: synthetic "Popular" first, then the real categories in first-seen order.
    static func categories(from items: [VideoTemplate]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for item in items where item.category != popularTitle && !seen.contains(item.category) {
            seen.insert(item.category)
            ordered.append(item.category)
        }
        return [popularTitle] + ordered
    }

    static func items(_ all: [VideoTemplate], in category: String) -> [VideoTemplate] {
        category == popularTitle ? Array(all.prefix(popularCount)) : all.filter { $0.category == category }
    }
}

// MARK: - Offline fallback catalog (bundled Ken Burns clips, used when the API is unreachable)
enum VideoTemplateCatalog {
    static let fallback: [VideoTemplate] = [
        make("cosmic_drift", "Cosmic Drift", "A dreamy cinematic portrait drifting through soft cosmic light", "Dreamy", "AstroGirl"),
        make("clay_morph", "Clay Morph", "A playful claymation character with a funny morphing expression", "Funny", "ClayFool"),
        make("neon_muse", "Neon Muse", "A trendy neon-lit portrait with smooth cinematic motion", "Trends", "GalleryGirl"),
        make("astro_duo", "Astro Duo", "Two friends launched into a vivid space adventure", "Trends", "AstroGirl"),
        make("melancholy", "Melancholy", "A soft melancholic portrait with slow emotional motion", "Sad", "GalleryGirl"),
        make("starlit_gaze", "Starlit Gaze", "A serene dreamy gaze beneath a starlit sky", "Dreamy", "AstroGirl"),
        make("goofy_bounce", "Goofy Bounce", "A goofy bouncing claymation loop with comedic timing", "Funny", "ClayFool"),
        make("daydream", "Daydream", "A soft daydream sequence with gentle light leaks", "Dreamy", "GalleryGirl"),
        make("sad_astronaut", "Sad Astronaut", "A lonely astronaut drifting in silence, a somber mood", "Sad", "AstroGirl")
    ]

    private static func make(_ id: String, _ title: String, _ prompt: String, _ category: String, _ poster: String) -> VideoTemplate {
        VideoTemplate(id: id, title: title, prompt: prompt, category: category, templateId: nil,
                      previewURL: nil, previewVideoName: "tpl_\(id)", posterName: poster, requiredPhotos: 1)
    }
}
