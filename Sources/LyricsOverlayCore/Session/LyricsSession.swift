import Foundation

/// Host-app coordinator: resolve lyrics, publish App Group snapshots for extensions.
public actor LyricsSession {
    private let store: SharedStoreing
    private let lyrics: LyricsServing
    private let monitor: NowPlayingMonitoring
    private let clock = LyricClock()

    public init(store: SharedStoreing, lyrics: LyricsServing, monitor: NowPlayingMonitoring) {
        self.store = store
        self.lyrics = lyrics
        self.monitor = monitor
    }

    @discardableResult
    public func refresh() async throws -> (playback: PlaybackSnapshot, lyrics: SyncedLyrics, lineIndex: Int?) {
        guard var playback = await monitor.current() else {
            throw LyricsServiceError.notFound
        }
        let elapsed = playback.projectedElapsed()
        playback.elapsed = elapsed
        playback.updatedAt = Date()

        let existing = try store.loadLyrics()
        let synced: SyncedLyrics
        if let existing,
           existing.track.title == playback.track.title,
           existing.track.artist == playback.track.artist {
            synced = existing
        } else {
            synced = try await lyrics.lyrics(for: playback.track)
            try store.saveLyrics(synced)
        }

        try store.savePlayback(playback)
        let index = clock.activeIndex(in: synced, elapsed: elapsed)
        return (playback, synced, index)
    }
}
