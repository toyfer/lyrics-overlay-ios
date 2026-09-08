import Foundation

public enum LyricsProviderKind: String, Sendable {
    case mock
    case localLRC
    case lrclib
    case musixmatch
}

public enum LyricsServiceError: Error, Sendable {
    case notFound
    case network(String)
    case decoding
    case missingAPIKey
    case disabled(String)
}

public protocol LyricsServing: Sendable {
    var kind: LyricsProviderKind { get }
    func lyrics(for track: TrackSnapshot) async throws -> SyncedLyrics
}

public struct LyricsRouter: LyricsServing {
    public let kind: LyricsProviderKind = .mock
    private let providers: [LyricsServing]

    public init(providers: [LyricsServing]) {
        self.providers = providers
    }

    public func lyrics(for track: TrackSnapshot) async throws -> SyncedLyrics {
        var lastError: Error = LyricsServiceError.notFound
        for provider in providers {
            do {
                return try await provider.lyrics(for: track)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}
