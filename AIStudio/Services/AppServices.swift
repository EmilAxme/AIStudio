import Foundation

// MARK: - AppServices
enum AppServices {
    static let userIdentifier = ApphudUserIdentifierProvider()
    static let network: NetworkService = URLSessionNetworkService()
    static let chat: ChatServicing = ChatAPIService(network: network, userProvider: userIdentifier)
    static let video: VideoGenerationServicing = VideoAPIService(network: network, userProvider: userIdentifier)
    static let subscription = SubscriptionService()
    static let chatHistory = ChatHistoryStore()
    static let videoHistory = VideoHistoryStore()
}
