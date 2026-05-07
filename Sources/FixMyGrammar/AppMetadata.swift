import Foundation

/// Release version: keep in sync with `Packaging/Info.plist` (`CFBundleShortVersionString`).
enum AppMetadata {
    static let fallbackMarketingVersion = "1.0.0"

    /// When running from `FixMyGrammar.app`, reads the bundle; otherwise falls back (e.g. `swift run`).
    static var marketingVersion: String {
        let fromBundle = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let fromBundle, !fromBundle.isEmpty { return fromBundle }
        return fallbackMarketingVersion
    }
}
