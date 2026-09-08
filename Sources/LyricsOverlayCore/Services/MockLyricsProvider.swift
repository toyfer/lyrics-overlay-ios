import Foundation

public struct MockLyricsProvider: LyricsServing {
    public let kind: LyricsProviderKind = .mock

    public init() {}

    public func lyrics(for track: TrackSnapshot) async throws -> SyncedLyrics {
        let sample = """
        [ti:\(track.title)]
        [ar:\(track.artist)]
        [00:00.00] (instrumental intro)
        [00:05.00] City lights in quiet rain
        [00:10.50] Soft metronome on the windowpane
        [00:16.00] We count the bars, not the hours
        [00:21.75] Sync the words to borrowed power
        [00:27.00] Mock lines only — timing demo
        [00:33.00] Replace with LRC you have rights to
        [00:39.50] Widget wakes on every line
        [00:45.00] Not once per second for all time
        [00:51.00] End of sample — loop or stop
        """
        let lines = LRCParser.parse(sample)
        var t = track
        if t.duration == nil {
            t.duration = (lines.last?.time ?? 60) + 8
        }
        return SyncedLyrics(track: t, lines: lines, source: .mock)
    }
}
