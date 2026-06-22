import UIKit

struct VideoRequest {
    let prompt: String
    let imageName: String
    let images: [UIImage]
    let aspectRatio: String
    let quality: String

    init(prompt: String, imageName: String, images: [UIImage] = [], aspectRatio: String, quality: String) {
        self.prompt = prompt
        self.imageName = imageName
        self.images = images
        self.aspectRatio = aspectRatio
        self.quality = quality
    }
}

// MARK: - ViewState
enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
