import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity payload. Start/update/end from the host app (not from the widget process).
public struct LyricsActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var line: String
        public var nextLine: String?
        public var elapsed: TimeInterval
        public var isPlaying: Bool

        public init(line: String, nextLine: String? = nil, elapsed: TimeInterval, isPlaying: Bool) {
            self.line = line
            self.nextLine = nextLine
            self.elapsed = elapsed
            self.isPlaying = isPlaying
        }
    }

    public var title: String
    public var artist: String

    public init(title: String, artist: String) {
        self.title = title
        self.artist = artist
    }
}

// Host-app helper sketch (copy into the app target):
public enum LyricsActivityController {
    @available(iOS 16.1, *)
    public static func start(track: TrackSnapshot, state: LyricsActivityAttributes.ContentState) throws {
        let attrs = LyricsActivityAttributes(title: track.title, artist: track.artist)
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(60))
        _ = try Activity.request(attributes: attrs, content: content, pushType: nil)
    }

    @available(iOS 16.1, *)
    public static func updateAll(line: String, next: String?, elapsed: TimeInterval, playing: Bool) async {
        let state = LyricsActivityAttributes.ContentState(
            line: line,
            nextLine: next,
            elapsed: elapsed,
            isPlaying: playing
        )
        for activity in Activity<LyricsActivityAttributes>.activities {
            let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(45))
            await activity.update(content)
        }
    }

    @available(iOS 16.1, *)
    public static func endAll() async {
        for activity in Activity<LyricsActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

@available(iOS 16.1, *)
struct LyricsLiveActivityView: View {
    let context: ActivityViewContext<LyricsActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(context.attributes.artist) — \(context.attributes.title)")
                .font(.caption2)
            Text(context.state.line)
                .font(.headline)
                .lineLimit(2)
            if let next = context.state.nextLine {
                Text(next)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
    }
}

/*
 Wire inside the Widget bundle:

 @main
 struct LyricsBundle: WidgetBundle {
     var body: some Widget {
         LyricsWidget()
         LyricsLiveActivityWidget()
     }
 }

 struct LyricsLiveActivityWidget: Widget {
     var body: some WidgetConfiguration {
         ActivityConfiguration(for: LyricsActivityAttributes.self) { context in
             LyricsLiveActivityView(context: context)
         } dynamicIsland: { context in
             DynamicIsland {
                 DynamicIslandExpandedRegion(.leading) {
                     Text(context.attributes.artist).font(.caption2)
                 }
                 DynamicIslandExpandedRegion(.bottom) {
                     Text(context.state.line).font(.headline)
                 }
             } compactLeading: {
                 Image(systemName: "text.quote")
             } compactTrailing: {
                 Text(context.state.line).font(.caption2).lineLimit(1)
             } minimal: {
                 Image(systemName: "text.quote")
             }
         }
     }
 }

 Info.plist (host app):
 NSSupportsLiveActivities = YES
*/
