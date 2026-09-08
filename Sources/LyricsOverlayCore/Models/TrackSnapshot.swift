import Foundation

public struct TrackSnapshot: Codable, Hashable, Sendable {
    public var title: String
    public var artist: String
    public var album: String?
    public var duration: TimeInterval?
    public var isrc: String?
    public var externalID: String?

    public init(
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval? = nil,
        isrc: String? = nil,
        externalID: String? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.isrc = isrc
        self.externalID = externalID
    }
}
