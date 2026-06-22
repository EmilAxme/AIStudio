import Foundation

struct VideoGenerationParameters {
    let prompt: String
    let imageData: Data?
    let aspectRatio: String
    let quality: String
    let durationSeconds: Int

    init(prompt: String, imageData: Data?, aspectRatio: String, quality: String, durationSeconds: Int = 5) {
        self.prompt = prompt
        self.imageData = imageData
        self.aspectRatio = aspectRatio
        self.quality = quality
        self.durationSeconds = durationSeconds
    }
}

// MARK: - VideoGenerationError
enum VideoGenerationError: LocalizedError {
    case failed
    case timedOut
    case noResultURL

    var errorDescription: String? {
        switch self {
        case .failed:
            return "Couldn't create the video. Please try again.".localized
        case .timedOut:
            return "Generation took too long. Please try again.".localized
        case .noResultURL:
            return "The video is ready, but the link is unavailable. Please try again.".localized
        }
    }
}

// MARK: - VideoGenerationServicing
protocol VideoGenerationServicing {
    func generate(_ parameters: VideoGenerationParameters) async throws -> URL
}

// MARK: - VideoAPIService
final class VideoAPIService: VideoGenerationServicing {
    private let network: NetworkService
    private let userProvider: UserIdentifierProviding

    private let pollInterval: UInt64 = 2 * 1_000_000_000
    private let maxPolls = 60

    init(network: NetworkService, userProvider: UserIdentifierProviding) {
        self.network = network
        self.userProvider = userProvider
    }

    func generate(_ parameters: VideoGenerationParameters) async throws -> URL {
        let userID = userProvider.userID
        let start = parameters.imageData == nil
            ? VideoEndpoint.text2video(parameters, userID: userID)
            : VideoEndpoint.image2video(parameters, userID: userID)

        let started = try await network.send(start, as: PixverseT2vResponse.self)
        return try await pollForResult(videoID: started.videoId, userID: userID)
    }

    private func pollForResult(videoID: Int, userID: String) async throws -> URL {
        for _ in 0..<maxPolls {
            try Task.checkCancellation()
            let status = try await network.send(
                VideoEndpoint.status(id: videoID, userID: userID),
                as: PixverseGenerationStatusResponse.self
            )
            let state = status.status.lowercased()
            if state.contains("fail") || state.contains("error") {
                throw VideoGenerationError.failed
            }
            if let urlString = status.videoUrl, let url = URL(string: urlString) {
                return url
            }
            try await Task.sleep(nanoseconds: pollInterval)
        }
        throw VideoGenerationError.timedOut
    }

    private static func apiQuality(_ label: String) -> String {
        switch label.lowercased() {
        case "360p": return "360p"
        case "540p": return "540p"
        case "720p": return "720p"
        case "1080p", "4k": return "1080p"
        default: return "1080p"
        }
    }

    private enum VideoEndpoint: Endpoint {
        case text2video(VideoGenerationParameters, userID: String)
        case image2video(VideoGenerationParameters, userID: String)
        case status(id: Int, userID: String)

        var baseURL: URL { AppConfig.API.videoBaseURL }

        var path: String {
            switch self {
            case .text2video: return "/api/v1/text2video"
            case .image2video: return "/api/v1/image2video"
            case .status: return "/api/v1/status"
            }
        }

        var method: HTTPMethod {
            switch self {
            case .status: return .get
            case .text2video, .image2video: return .post
            }
        }

        var queryItems: [URLQueryItem] {
            var items: [URLQueryItem]
            let userID: String
            switch self {
            case .text2video(_, let id), .image2video(_, let id):
                userID = id
                items = []
            case .status(let videoID, let id):
                userID = id
                items = [URLQueryItem(name: "id", value: String(videoID))]
            }
            items.append(URLQueryItem(name: "user_id", value: userID))
            items.append(URLQueryItem(name: "app_id", value: AppConfig.API.applicationID))
            return items
        }

        var body: HTTPBody? {
            switch self {
            case .text2video(let params, _):
                return .formURLEncoded([
                    "prompt": params.prompt,
                    "duration": String(params.durationSeconds),
                    "model": "v6",
                    "quality": VideoAPIService.apiQuality(params.quality),
                    "aspect_ratio": params.aspectRatio
                ])
            case .image2video(let params, _):
                var form = MultipartFormData()
                form.addField(name: "prompt", value: params.prompt)
                form.addField(name: "duration", value: String(params.durationSeconds))
                form.addField(name: "model", value: "v6")
                form.addField(name: "quality", value: VideoAPIService.apiQuality(params.quality))
                if let data = params.imageData {
                    form.addFile(name: "image", filename: "upload.jpg", mimeType: "image/jpeg", data: data)
                }
                return .multipart(form)
            case .status:
                return nil
            }
        }
    }

    private struct PixverseT2vResponse: Decodable {
        let videoId: Int
    }

    private struct PixverseGenerationStatusResponse: Decodable {
        let status: String
        let videoUrl: String?
    }
}
