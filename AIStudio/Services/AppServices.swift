import Foundation

protocol ChatServicing {
    func reply(to message: String, completion: @escaping (ChatMessage) -> Void)
}

protocol VideoGenerationServicing {
    func generate(
        request: VideoRequest,
        shouldFail: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}

protocol SubscriptionServicing {
    var isPremium: Bool { get }
    func activate(plan: SubscriptionPlan)
}

enum MockServiceError: LocalizedError {
    case generationFailed

    var errorDescription: String? { "We couldn't create this video. Please try again." }
}

final class MockChatService: ChatServicing {
    func reply(to message: String, completion: @escaping (ChatMessage) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            completion(
                ChatMessage(
                    sender: .assistant,
                    text: "Here is a polished version you can send:\n\nWelcome to the team! We're excited to have you with us and look forward to working together. Let us know if you need anything as you get started.",
                    title: "Welcome to the team!"
                )
            )
        }
    }
}

final class MockVideoGenerationService: VideoGenerationServicing {
    func generate(
        request: VideoRequest,
        shouldFail: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(shouldFail ? .failure(MockServiceError.generationFailed) : .success(()))
        }
    }
}

final class MockSubscriptionService: SubscriptionServicing {
    private(set) var isPremium = false

    func activate(plan: SubscriptionPlan) {
        isPremium = true
    }
}

enum AppServices {
    static let chat: ChatServicing = MockChatService()
    static let video: VideoGenerationServicing = MockVideoGenerationService()
    static let subscription: SubscriptionServicing = MockSubscriptionService()
}
