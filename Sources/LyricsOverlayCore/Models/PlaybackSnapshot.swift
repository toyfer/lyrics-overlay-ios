import Foundation

public struct PlaybackSnapshot: Codable, Hashable, Sendable {
    public var track: TrackSnapshot
    public var elapsed: TimeInterval
    public var isPlaying: Bool
    public var updatedAt: Date

    public init(
        track: TrackSnapshot,
        elapsed: TimeInterval,
        isPlaying: Bool,
        updatedAt: Date = Date()
    ) {
        self.track = track
        self.elapsed = elapsed
        self.isPlaying = isPlaying
        self.updatedAt = updatedAt
    }

    /// Best-effort current head position after time has passed since `updatedAt`.
    public func projectedElapsed(at date: Date = Date()) -> TimeInterval {
        guard isPlaying else { return elapsed }
        let delta = date.timeIntervalSince(updatedAt)
        guard delta > 0 else { return elapsed }
        if let duration = track.duration {
            return min(elapsed + delta, duration)
        }
        return elapsed + delta
    }
}
