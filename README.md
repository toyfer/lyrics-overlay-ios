# Lyrics Overlay iOS

Personal **synced-lyrics** skeleton for iPhone: in-app view, **WidgetKit**, and **Live Activities**.
Mock / local `.lrc` first. Optional network providers are stubs only.

> Not App Store–ready. No floating overlay (iOS cannot do true always-on overlay like Android without private APIs). CarPlay is out of MVP scope.

**Repo:** https://github.com/toyfer/lyrics-overlay-ios

## What this is

| Layer | Status |
| --- | --- |
| Domain models + LRC parser | Implemented (no compile guarantee; drop into Xcode) |
| Sync clock (line index from elapsed time) | Implemented |
| App Group shared store protocol | Implemented |
| Mock lyrics provider | Implemented |
| LRCLIB HTTP stub | Implemented (personal / experimental) |
| Musixmatch stub | Interface only (needs commercial key + ToS) |
| SwiftUI player shell | Sketch |
| WidgetKit timeline | Sketch |
| ActivityKit Live Activity | Sketch |
| Now Playing / MusicKit bridge | Protocol + TODO |
| App Store / paid API | Not included |

## Quick map

```text
Sources/LyricsOverlayCore/     Shared models, LRC, clock, providers, store
App/LyricsOverlayApp/          SwiftUI host app sketch
Extensions/LyricsWidget/       Home/Lock Screen widget sketch
Extensions/LyricsActivity/     Live Activity attributes + UI sketch
Resources/Sample/              Sample .lrc
docs/API.md                    Lyrics API decision notes
```

## Requirements (when you build)

- Mac + Xcode 15+ (Swift 5.9+)
- iOS 17+ recommended (Live Activities)
- Apple ID (free Personal Team is enough for on-device sideload)
- App Group capability: `group.your.lyricsoverlay` (change the id)
- `NSSupportsLiveActivities` = `YES` in the host app Info.plist

### Xcode wiring (manual)

1. Create an iOS App project `LyricsOverlay`.
2. Add files under `Sources/LyricsOverlayCore` to a shared framework **or** to app + extensions targets.
3. Add Widget Extension + (optional) include Live Activity scene in the widget extension (common pattern).
4. Enable App Groups on **App** and **Extension** with the same id.
5. Replace team / bundle ids.

Compile is intentionally left to you.

## Design rules (short)

- Widget / Live Activity updates are **OS-budgeted**. Drive updates from **line-change events**, not a 1 Hz UI timer pretending to be a mini app.
- Share state via **App Group** (`UserDefaults(suiteName:)` or file in the container). Do **not** use `UserDefaults.standard` across processes.
- Timeline reload: schedule the **next line** boundary (see `LyricClock` + widget provider).
- Lyrics text on a public store build needs a **license**. Mock and user-supplied LRC are for personal/dev use.

## API strategy (summary)

Full write-up: [docs/API.md](docs/API.md).

| Source | Synced lines | Auth | OK for personal sideload experiment | OK for App Store product |
| --- | --- | --- | --- | --- |
| Local `.lrc` / mock | Yes | None | Yes | Only if you own/license the text |
| **LRCLIB** | Yes (LRC) | None typical | Common in OSS players; still **not a rights grant** | Risky / usually no without your own rights |
| **Musixmatch Pro API** | Yes (licensed catalog) | Key + contract | With their plan rules | Intended path for commercial display |
| Spotify Web API | No public lyrics | OAuth | Use for metadata / playback context only | Lyrics not a public API feature |
| Apple Music / MusicKit | Catalog & playback | Developer token + user token | Playback + Now Playing | Timed lyrics for arbitrary 3rd-party UI are **not** a general-purpose public lyrics dump API |
| Genius | Mostly unsynced; ToS tight | Token | Research only | Display rights limited |

**Recommendation for this repo**

1. Default: `MockLyricsProvider` + `Resources/Sample`.
2. Personal experiments: `LRCLIBLyricsProvider` behind a flag (no key in git).
3. If you ever ship: talk to **Musixmatch Pro** (or another licensed provider) and keep attribution / caching rules they require.
4. Do not scrape Musixmatch / Genius / streaming apps.

## Run modes (product)

- **A. Sideload personal tool** — free or paid Apple Developer account; local LRC; no Store review.
- **B. Store utility without catalog** — user imports LRC / owns content; still follow guideline 5.x IP.
- **C. Store catalog lyrics** — licensed API + review narrative; paid Program required.

## License

MIT for **this code**. Sample lyric lines in mock data are **placeholder fiction** for timing demos only.
Third-party APIs remain under their own terms.
