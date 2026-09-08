import Foundation

/// Experimental personal-use client for lrclib.net style API.
/// This is **not** a display license. Prefer mock/local for demos; see docs/API.md.
public struct LRCLIBLyricsProvider: LyricsServing {
    public let kind: LyricsProviderKind = .lrclib
    public var baseURL: URL
    private let session: URLSession

    public init(
        baseURL: URL = URL(string: "https://lrclib.net")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    public func lyrics(for track: TrackSnapshot) async throws -> SyncedLyrics {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/get"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "track_name", value: track.title)
        ]
        if let album = track.album {
            items.append(URLQueryItem(name: "album_name", value: album))
        }
        if let duration = track.duration {
            items.append(URLQueryItem(name: "duration", value: String(Int(duration.rounded()))))
        }
        components.queryItems = items
        guard let url = components.url else { throw LyricsServiceError.network("bad url") }

        var request = URLRequest(url: url)
        request.setValue("lyrics-overlay-ios (personal experiment)", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LyricsServiceError.network(String(describing: error))
        }

        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw LyricsServiceError.notFound
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw LyricsServiceError.network("status")
        }

        let dto: LRCLIBGetResponse
        do {
            dto = try JSONDecoder().decode(LRCLIBGetResponse.self, from: data)
        } catch {
            throw LyricsServiceError.decoding
        }

        if dto.instrumental == true {
            return SyncedLyrics(
                track: track,
                lines: [LyricLine(time: 0, text: "(instrumental)")],
                source: .lrclib
            )
        }

        guard let synced = dto.syncedLyrics, !synced.isEmpty else {
            if let plain = dto.plainLyrics, !plain.isEmpty {
                let rough = plain.split(whereSeparator: \.isNewline).enumerated().map { idx, text in
                    LyricLine(time: TimeInterval(idx) * 3, text: String(text))
                }
                return SyncedLyrics(track: track, lines: rough, source: .lrclib)
            }
            throw LyricsServiceError.notFound
        }

        let lines = LRCParser.parse(synced)
        guard !lines.isEmpty else { throw LyricsServiceError.notFound }
        var t = track
        if let d = dto.duration { t.duration = TimeInterval(d) }
        return SyncedLyrics(track: t, lines: lines, source: .lrclib)
    }
}

private struct LRCLIBGetResponse: Decodable {
    var id: Int?
    var name: String?
    var trackName: String?
    var artistName: String?
    var albumName: String?
    var duration: Double?
    var instrumental: Bool?
    var plainLyrics: String?
    var syncedLyrics: String?
}
