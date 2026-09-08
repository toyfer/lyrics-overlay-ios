import Foundation

public struct LocalLRCFileProvider: LyricsServing {
    public let kind: LyricsProviderKind = .localLRC
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func lyrics(for track: TrackSnapshot) async throws -> SyncedLyrics {
        let raw = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = LRCParser.parse(raw)
        guard !lines.isEmpty else { throw LyricsServiceError.notFound }
        let meta = LRCParser.parseMetadata(raw)
        var resolved = track
        if resolved.title.isEmpty { resolved.title = meta.title ?? track.title }
        if resolved.artist.isEmpty { resolved.artist = meta.artist ?? track.artist }
        if resolved.album == nil { resolved.album = meta.album }
        return SyncedLyrics(track: resolved, lines: lines, source: .localLRC)
    }
}
