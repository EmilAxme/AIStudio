import UIKit

struct VideoRequest {
    let title: String
    let prompt: String
    let imageName: String
    let images: [UIImage]
    let aspectRatio: String
    let quality: String
    let templateId: Int?
    let transition: Bool

    init(title: String, prompt: String, imageName: String = "", images: [UIImage] = [], aspectRatio: String, quality: String, templateId: Int? = nil, transition: Bool = false) {
        self.title = title
        self.prompt = prompt
        self.imageName = imageName
        self.images = images
        self.aspectRatio = aspectRatio
        self.quality = quality
        self.templateId = templateId
        self.transition = transition
    }
}

// MARK: - ViewState
enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
