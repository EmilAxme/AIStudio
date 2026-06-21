import Foundation

/// Central, type-safe configuration for the app's backend + Apphud integration.
///
/// In production these secrets (bearer token, Apphud key) would be injected from
/// an `.xcconfig` / Keychain / remote config rather than hard-coded. They live
/// here so nothing is hard-coded *at the call site* — every consumer reads from
/// `AppConfig`, giving a single place to swap them out.
enum AppConfig {
    enum API {
        /// Dola text-chat service. The `/dola` prefix is part of the path space
        /// (e.g. `…/dola/chats/{id}/messages`), so endpoints append `/chats/…`.
        static let chatBaseURL = URL(string: "https://nebulaapps.site/dola")!
        /// PixVerse video service. Endpoints append `/api/v1/…`.
        static let videoBaseURL = URL(string: "https://nebulaapps.site/pixverse")!
        /// Permanent (non-refreshable) JWT issued for this test integration.
        static let bearerToken = "REDACTED"
        /// `app_id` query value the backend keys catalogs/quotas on. NOTE: this is
        /// the *backend* application id and is intentionally different from the
        /// app's bundle id (`com.labs.fviu`).
        static let applicationID = "com.test.test"
    }

    enum Apphud {
        static let apiKey = "app_FmCjFTwjWpcLSafxT8vCDeVffJyfFS"
        static let paywallID = "main"
    }
}
