import UIKit

struct VideoRequest {
    /// Prompt sent to PixVerse (the template title when the user hasn't typed one).
    let prompt: String
    /// Asset name used as the result-screen poster while/after generating.
    let imageName: String
    /// Photos picked on the Create screen. Empty -> text-to-video; otherwise the
    /// first image drives image-to-video.
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

enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
