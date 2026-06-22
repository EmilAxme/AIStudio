import Foundation
import ApphudSDK

protocol UserIdentifierProviding {
    var userID: String { get }
}

// MARK: - UserIdentifierSanitizer
enum UserIdentifierSanitizer {
    private static let allowed = Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:-"
    )

    static func sanitize(_ raw: String) -> String {
        String(raw.filter { allowed.contains($0) }.prefix(36))
    }
}

// MARK: - ApphudUserIdentifierProvider
final class ApphudUserIdentifierProvider: UserIdentifierProviding {
    private let fallback: UserIdentifierProviding
    private let lock = NSLock()
    private var cached: String?

    init(fallback: UserIdentifierProviding = DeviceUserIdentifierProvider()) {
        self.fallback = fallback
    }

    @MainActor func refresh() {
        let id = UserIdentifierSanitizer.sanitize(Apphud.userID())
        lock.lock(); cached = id.isEmpty ? nil : id; lock.unlock()
    }

    var userID: String {
        lock.lock(); let value = cached; lock.unlock()
        if let value { return value }
        if Thread.isMainThread {
            let id = UserIdentifierSanitizer.sanitize(MainActor.assumeIsolated { Apphud.userID() })
            if !id.isEmpty {
                lock.lock(); cached = id; lock.unlock()
                return id
            }
        }
        return fallback.userID
    }
}

// MARK: - DeviceUserIdentifierProvider
struct DeviceUserIdentifierProvider: UserIdentifierProviding {
    private static let key = "app.identity.deviceUserID"

    var userID: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: Self.key), !existing.isEmpty {
            return existing
        }
        let generated = UserIdentifierSanitizer.sanitize(UUID().uuidString)
        defaults.set(generated, forKey: Self.key)
        return generated
    }
}
