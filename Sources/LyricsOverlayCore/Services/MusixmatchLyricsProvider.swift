import Foundation

/// Commercial path stub. Obtain a key and contract from Musixmatch Pro before calling production endpoints.
/// https://www.musixmatch.com/pro/api/
public struct MusixmatchLyricsProvider: LyricsServing {
    public let kind: LyricsProviderKind = .musixmatch
    public var apiKey: String
    public var baseURL: URL

    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.musixmatch.com/ws/1.1/")!
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    public func lyrics(for track: TrackSnapshot) async throws -> SyncedLyrics {
        guard !apiKey.isEmpty else { throw LyricsServiceError.missingAPIKey }

        // Intentionally unimplemented network calls:
        // Matching + subtitle endpoints, attribution, and caching must follow your agreement.
        throw LyricsServiceError.disabled(
            "Musixmatch: add signed URL calls per your Pro API docs; do not commit keys."
        )
    }
}
