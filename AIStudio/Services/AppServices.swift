import Foundation

/// Composition root: builds the live service graph and exposes it for default DI.
///
/// Controllers receive services through their initializers (defaulting to these
/// instances), so the whole graph can be swapped in tests/previews without
/// editing call sites — and no service is a global singleton beyond this root.
enum AppServices {
    static let userIdentifier = ApphudUserIdentifierProvider()
    static let network: NetworkService = URLSessionNetworkService()
    static let chat: ChatServicing = ChatAPIService(network: network, userProvider: userIdentifier)
    static let video: VideoGenerationServicing = VideoAPIService(network: network, userProvider: userIdentifier)
    static let subscription = SubscriptionService()
}
