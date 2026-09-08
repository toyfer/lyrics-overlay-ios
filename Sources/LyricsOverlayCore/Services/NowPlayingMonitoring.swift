import Foundation

/// Bridge to whatever actually plays audio.
/// Implementations might wrap MPNowPlayingInfoCenter, MediaPlayer, MusicKit, or a local AVPlayer.
public protocol NowPlayingMonitoring: Sendable {
    func current() async -> PlaybackSnapshot?
}

/// Demo monitor that pretends a track is playing from t=0.
public actor FakeNowPlayingMonitor: NowPlayingMonitoring {
    private let track: TrackSnapshot
    private let startedAt: Date
    private var playing: Bool

    public init(track: TrackSnapshot, playing: Bool = true) {
        self.track = track
        self.startedAt = Date()
        self.playing = playing
    }

    public func setPlaying(_ value: Bool) {
        playing = value
    }

    public func current() async -> PlaybackSnapshot? {
        let elapsed = Date().timeIntervalSince(startedAt)
        return PlaybackSnapshot(
            track: track,
            elapsed: elapsed,
            isPlaying: playing,
            updatedAt: Date()
        )
    }
}

/*
 Example production sketch (not compiled here):

 import MediaPlayer

 struct SystemNowPlayingMonitor: NowPlayingMonitoring {
     func current() async -> PlaybackSnapshot? {
         let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
         // map title/artist/elapsed/rate → PlaybackSnapshot
         return nil
     }
 }
*/
