import Foundation

// MARK: - AppConfig
enum AppConfig {
    enum API {
        static let chatBaseURL = URL(string: "https://nebulaapps.site/dola")!
        static let videoBaseURL = URL(string: "https://nebulaapps.site/pixverse")!
        static let bearerToken = "REDACTED"
        static let applicationID = "com.test.test"
    }

    enum Apphud {
        static let apiKey = "app_FmCjFTwjWpcLSafxT8vCDeVffJyfFS"
        static let paywallID = "main"
    }
}
