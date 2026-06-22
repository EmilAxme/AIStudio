import Foundation
import ApphudSDK

/// Supplies the `user_id` sent with every API request. Abstracted behind a
/// protocol so the source (Apphud / device / a test stub) can be swapped via DI
/// without touching the networking services.
protocol UserIdentifierProviding {
    var userID: String { get }
}

/// Backend `user_id` constraints: 1-36 chars, `^[A-Za-z0-9._:-]+$`.
enum UserIdentifierSanitizer {
    private static let allowed = Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:-"
    )

    static func sanitize(_ raw: String) -> String {
        String(raw.filter { allowed.contains($0) }.prefix(36))
    }
}

/// Primary provider: the Apphud user id (stable, persisted by the SDK).
///
/// `Apphud.userID()` is `@MainActor`, but our network calls run off the main
/// actor - so we cache the value (primed once on launch) and read the cache.
/// Falls back to a stable device UUID if Apphud's id is empty.
final class ApphudUserIdentifierProvider: UserIdentifierProviding {
    private let fallback: UserIdentifierProviding
    private let lock = NSLock()
    private var cached: String?

    init(fallback: UserIdentifierProviding = DeviceUserIdentifierProvider()) {
        self.fallback = fallback
    }

    /// Capture Apphud's id on the main actor. Call once after `Apphud.start`.
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

/// Fallback provider: a stable UUID persisted in `UserDefaults`.
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
