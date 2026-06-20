import Foundation

struct VideoRequest {
    let imageName: String
    let aspectRatio: String
    let quality: String
}

enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
