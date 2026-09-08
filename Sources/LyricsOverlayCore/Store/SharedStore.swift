import Foundation

public enum AppGroupConfig {
    /// Change to your identifier and enable the same App Group on app + extensions.
    public static var suiteName = "group.your.lyricsoverlay"
}

public protocol SharedStoreing: Sendable {
    func savePlayback(_ snapshot: PlaybackSnapshot) throws
    func loadPlayback() throws -> PlaybackSnapshot?
    func saveLyrics(_ lyrics: SyncedLyrics) throws
    func loadLyrics() throws -> SyncedLyrics?
    func clear() throws
}

public final class AppGroupStore: SharedStoreing, @unchecked Sendable {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let playback = "playback_snapshot_v1"
        static let lyrics = "synced_lyrics_v1"
    }

    public init(suiteName: String = AppGroupConfig.suiteName) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("App Group UserDefaults unavailable: \(suiteName). Enable App Groups.")
        }
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func savePlayback(_ snapshot: PlaybackSnapshot) throws {
        let data = try encoder.encode(snapshot)
        defaults.set(data, forKey: Key.playback)
    }

    public func loadPlayback() throws -> PlaybackSnapshot? {
        guard let data = defaults.data(forKey: Key.playback) else { return nil }
        return try decoder.decode(PlaybackSnapshot.self, from: data)
    }

    public func saveLyrics(_ lyrics: SyncedLyrics) throws {
        let data = try encoder.encode(lyrics)
        defaults.set(data, forKey: Key.lyrics)
    }

    public func loadLyrics() throws -> SyncedLyrics? {
        guard let data = defaults.data(forKey: Key.lyrics) else { return nil }
        return try decoder.decode(SyncedLyrics.self, from: data)
    }

    public func clear() throws {
        defaults.removeObject(forKey: Key.playback)
        defaults.removeObject(forKey: Key.lyrics)
    }
}

/// In-memory store for previews and unit-style experiments without App Groups.
public final class MemoryStore: SharedStoreing, @unchecked Sendable {
    private var playback: PlaybackSnapshot?
    private var lyrics: SyncedLyrics?

    public init() {}

    public func savePlayback(_ snapshot: PlaybackSnapshot) throws { playback = snapshot }
    public func loadPlayback() throws -> PlaybackSnapshot? { playback }
    public func saveLyrics(_ lyrics: SyncedLyrics) throws { self.lyrics = lyrics }
    public func loadLyrics() throws -> SyncedLyrics? { lyrics }
    public func clear() throws {
        playback = nil
        lyrics = nil
    }
}
