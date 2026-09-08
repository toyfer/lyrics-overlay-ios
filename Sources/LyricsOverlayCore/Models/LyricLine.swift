import Foundation

public struct LyricLine: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var time: TimeInterval
    public var text: String

    public init(id: UUID = UUID(), time: TimeInterval, text: String) {
        self.id = id
        self.time = time
        self.text = text
    }
}

public struct SyncedLyrics: Codable, Hashable, Sendable {
    public var track: TrackSnapshot
    public var lines: [LyricLine]
    public var source: LyricsSource
    public var fetchedAt: Date

    public init(
        track: TrackSnapshot,
        lines: [LyricLine],
        source: LyricsSource,
        fetchedAt: Date = Date()
    ) {
        self.track = track
        self.lines = lines.sorted { $0.time < $1.time }
        self.source = source
        self.fetchedAt = fetchedAt
    }

    public var isEmpty: Bool { lines.isEmpty }
}

public enum LyricsSource: String, Codable, Sendable {
    case mock
    case localLRC
    case lrclib
    case musixmatch
    case unknown
}
