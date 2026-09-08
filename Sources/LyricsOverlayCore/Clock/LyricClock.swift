import Foundation

public struct LyricClock: Sendable {
    public init() {}

    /// Index of the last line whose start time is <= elapsed. nil if before first line.
    public func activeIndex(in lyrics: SyncedLyrics, elapsed: TimeInterval) -> Int? {
        let lines = lyrics.lines
        guard !lines.isEmpty else { return nil }
        if elapsed < lines[0].time { return nil }
        var lo = 0
        var hi = lines.count - 1
        var answer = 0
        while lo <= hi {
            let mid = (lo + hi) / 2
            if lines[mid].time <= elapsed {
                answer = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return answer
    }

    public func activeLine(in lyrics: SyncedLyrics, elapsed: TimeInterval) -> LyricLine? {
        guard let i = activeIndex(in: lyrics, elapsed: elapsed) else { return nil }
        return lyrics.lines[i]
    }

    /// Seconds until the next line starts. nil if none (stay on last).
    public func secondsUntilNextLine(in lyrics: SyncedLyrics, elapsed: TimeInterval) -> TimeInterval? {
        let lines = lyrics.lines
        guard !lines.isEmpty else { return nil }
        guard let i = activeIndex(in: lyrics, elapsed: elapsed) else {
            return max(0, lines[0].time - elapsed)
        }
        let next = i + 1
        guard next < lines.count else { return nil }
        return max(0, lines[next].time - elapsed)
    }

    public func surrounding(
        in lyrics: SyncedLyrics,
        elapsed: TimeInterval,
        before: Int = 1,
        after: Int = 1
    ) -> (previous: [LyricLine], current: LyricLine?, next: [LyricLine]) {
        guard let i = activeIndex(in: lyrics, elapsed: elapsed) else {
            let head = Array(lyrics.lines.prefix(after))
            return ([], nil, head)
        }
        let lines = lyrics.lines
        let start = max(0, i - before)
        let prev = Array(lines[start..<i])
        let current = lines[i]
        let end = min(lines.count, i + 1 + after)
        let next = Array(lines[(i + 1)..<end])
        return (prev, current, next)
    }
}
