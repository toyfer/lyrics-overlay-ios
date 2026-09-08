import WidgetKit
import SwiftUI

// MARK: - Timeline model

struct LyricsEntry: TimelineEntry {
    let date: Date
    let title: String
    let artist: String
    let line: String
    let nextLine: String?
}

struct LyricsTimelineProvider: TimelineProvider {
    private let clock = LyricClock()

    func placeholder(in context: Context) -> LyricsEntry {
        LyricsEntry(
            date: Date(),
            title: "Sample",
            artist: "Demo",
            line: "City lights in quiet rain",
            nextLine: "Soft metronome on the windowpane"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LyricsEntry) -> Void) {
        completion(makeEntry(now: Date()) ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LyricsEntry>) -> Void) {
        let now = Date()
        guard let entry = makeEntry(now: now) else {
            let empty = LyricsEntry(
                date: now,
                title: "—",
                artist: "",
                line: "No lyrics in App Group",
                nextLine: "Open the app once"
            )
            completion(Timeline(entries: [empty], policy: .after(now.addingTimeInterval(15 * 60))))
            return
        }

        // Budget-friendly: one entry now; reload around the next lyric boundary (clamped).
        var policyDate = now.addingTimeInterval(15)
        if let lyrics = try? AppGroupStore().loadLyrics(),
           let playback = try? AppGroupStore().loadPlayback() {
            let elapsed = playback.projectedElapsed(at: now)
            if let dt = clock.secondsUntilNextLine(in: lyrics, elapsed: elapsed) {
                policyDate = now.addingTimeInterval(min(max(dt, 1), 15 * 60))
            }
        }

        completion(Timeline(entries: [entry], policy: .after(policyDate)))
    }

    private func makeEntry(now: Date) -> LyricsEntry? {
        let store: AppGroupStore
        do {
            store = AppGroupStore()
        } catch {
            return nil
        }
        guard let lyrics = try? store.loadLyrics(),
              let playback = try? store.loadPlayback() else { return nil }
        let elapsed = playback.projectedElapsed(at: now)
        let surround = clock.surrounding(in: lyrics, elapsed: elapsed, before: 0, after: 1)
        return LyricsEntry(
            date: now,
            title: lyrics.track.title,
            artist: lyrics.track.artist,
            line: surround.current?.text ?? "…",
            nextLine: surround.next.first?.text
        )
    }
}

struct LyricsWidgetView: View {
    var entry: LyricsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(entry.artist) · \(entry.title)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(entry.line)
                .font(.headline)
                .lineLimit(3)
            if let next = entry.nextLine {
                Text(next)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct LyricsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LyricsWidget", provider: LyricsTimelineProvider()) { entry in
            LyricsWidgetView(entry: entry)
        }
        .configurationDisplayName("Synced Lyrics")
        .description("Shows the current mock/synced line from the App Group store.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
