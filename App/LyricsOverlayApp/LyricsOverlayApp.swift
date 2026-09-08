import SwiftUI

@main
struct LyricsOverlayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var model = PlayerViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(model.trackLabel)
                    .font(.headline)
                Text(model.status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                List(model.visibleLines) { line in
                    HStack {
                        Text(format(line.time))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 64, alignment: .leading)
                        Text(line.text)
                            .fontWeight(line.id == model.currentID ? .bold : .regular)
                            .foregroundStyle(line.id == model.currentID ? .primary : .secondary)
                    }
                }
                .listStyle(.plain)

                HStack {
                    Button(model.isPlaying ? "Pause" : "Play") {
                        model.toggle()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reload mock") {
                        Task { await model.reload() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Lyrics Overlay")
            .task { await model.reload() }
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = t.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%05.2f", m, s)
    }
}

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var visibleLines: [LyricLine] = []
    @Published var currentID: UUID?
    @Published var status: String = "Idle"
    @Published var trackLabel: String = "—"
    @Published var isPlaying = true

    private let store = MemoryStore()
    private let clock = LyricClock()
    private var lyrics: SyncedLyrics?
    private var ticker: Task<Void, Never>?
    private var startedAt = Date()
    private var baseElapsed: TimeInterval = 0

    func reload() async {
        let track = TrackSnapshot(
            title: "Sample Timing Demo",
            artist: "Lyrics Overlay",
            album: "Dev",
            duration: 60
        )
        trackLabel = "\(track.artist) — \(track.title)"
        do {
            let synced = try await MockLyricsProvider().lyrics(for: track)
            lyrics = synced
            try store.saveLyrics(synced)
            visibleLines = synced.lines
            baseElapsed = 0
            startedAt = Date()
            status = "Mock \(synced.lines.count) lines"
            startTicker()
            // When using real extensions, also write AppGroupStore + reload timelines / activities.
        } catch {
            status = "Error: \(error)"
        }
    }

    func toggle() {
        if isPlaying {
            baseElapsed = elapsed()
            isPlaying = false
            ticker?.cancel()
        } else {
            startedAt = Date()
            isPlaying = true
            startTicker()
        }
    }

    private func elapsed() -> TimeInterval {
        if isPlaying {
            return baseElapsed + Date().timeIntervalSince(startedAt)
        }
        return baseElapsed
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.tick()
                // UI may tick ~4 Hz; widgets should NOT mirror this pattern.
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
    }

    private func tick() async {
        guard let lyrics else { return }
        let e = elapsed()
        currentID = clock.activeLine(in: lyrics, elapsed: e)?.id
        let playback = PlaybackSnapshot(
            track: lyrics.track,
            elapsed: e,
            isPlaying: isPlaying
        )
        try? store.savePlayback(playback)
        if let wait = clock.secondsUntilNextLine(in: lyrics, elapsed: e), wait == 0 {
            // boundary
        }
        status = String(format: "t=%.1fs playing=%@", e, isPlaying ? "yes" : "no")
    }
}
