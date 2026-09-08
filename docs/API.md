# Lyrics API notes

Last reviewed: 2026-09-08 (public web docs / vendor pages). Re-check before any commercial use.

## Goal

Feed **time-synced** lines into:

- in-app UI
- WidgetKit
- Live Activities

Playback position comes from the device (local player, Now Playing, or MusicKit). The lyrics API only supplies text + timestamps.

## Comparison

### 1. Local `.lrc` / bundled mock (default)

- **Pros:** No key, offline, deterministic, fine for sideload learning.
- **Cons:** You must supply files; no world catalog.
- **Store:** Allowed only for content you have rights to (user-owned imports are the usual story).

Use `LRCParser` + `MockLyricsProvider`.

### 2. LRCLIB (https://lrclib.net)

Community database of synchronized lyrics (LRC-style). OSS server: [tranxuanthang/lrclib](https://github.com/tranxuanthang/lrclib).

Typical client usage (wrappers such as [lrclib-api](https://lrclib.js.org/) document shapes like):

- Search / get by title, artist, album, duration
- Response fields often include `plainLyrics`, `syncedLyrics` (LRC string), `duration`, ids

**Pros**

- Free, no API key in common usage
- Real synced lines for experiments and personal players
- Easy to map through existing `LRCParser`

**Cons / risk**

- Crowdsourced corpus is **not** the same as a display license for your App Store app
- Availability, rate limits, and mirroring can change
- Shipping a product that bulk-fetches and shows LRCLIB text can create **IP exposure**

**Fit for this project:** optional provider behind `LyricsProviderKind.lrclib`, personal sideload only unless you obtain separate rights.

Stub: `LRCLIBLyricsProvider`.

Suggested endpoints to verify against current docs when implementing:

```text
GET https://lrclib.net/api/get?artist_name=...&track_name=...&album_name=...&duration=...
GET https://lrclib.net/api/search?q=...
```

(Exact query params can evolve — confirm on lrclib.net before release.)

### 3. Musixmatch Pro API (https://www.musixmatch.com/pro/api/)

Licensed lyrics platform aimed at products that need a legal catalog, attribution, and commercial terms. Starter → enterprise style packaging on their Pro site.

**Pros**

- Correct lane for **monetized / public** lyrics display when under contract
- Large catalog, subtitle/sync oriented industry use

**Cons**

- Key + plan; free hobby tiers (when offered) are usually **not** “ship a lyrics widget app” rights
- Caching, branding, and matching rules are contractual
- Must not scrape the consumer Musixmatch apps/site as a substitute

**Fit:** `MusixmatchLyricsProvider` is a **protocol-shaped stub** only. No API key belongs in git.

### 4. Spotify

- Official **Web API** is for catalog, playback context, playlist, etc.
- **Lyrics are not** a supported general public API feature for third-party lyric UIs.
- 2025–2026 developer access has been tightened further for many Web API use cases — do not plan a product on “undocumented lyrics endpoints”.

**Fit:** optional *track metadata / external id* helper later; not a lyrics source.

### 5. Apple Music / MusicKit

- MusicKit + Apple Music API: search, play, library, catalog metadata.
- System Music app shows timed lyrics to subscribers; that is **not** equivalent to “any app may redistribute timed lyrics via a documented dump API”.
- Use MusicKit for **playback and Now Playing alignment** when the user plays Apple Music from your app or as a signal source — not as an assumed lyrics CDN.

**Fit:** `NowPlayingMonitoring` bridge; lyrics still from LRC / licensed provider.

### 6. Genius and scrapers

- Genius has developer terms that restrict many display cases; synced karaoke is not their product lane.
- HTML scraping of any major lyrics site is the wrong approach for Store and for stability.

## Decision matrix (practical)

| Your intent | Provider |
| --- | --- |
| Learn Widget + LA + sync clock | Mock / sample LRC |
| Personal sideload player with internet fetch | LRCLIB flag (accept legal ambiguity; keep private) |
| Public App Store + catalog | Musixmatch Pro or equivalent **written license** |
| Apple Music-only UX | MusicKit playback + licensed lyrics side channel |
| Spotify-only UX | Spotify playback APIs (where allowed) + licensed lyrics side channel |

## Implementation policy in code

```text
LyricsServing
  ├ MockLyricsProvider      // default ON
  ├ LocalLRCFileProvider    // user files / bundle
  ├ LRCLIBLyricsProvider    // opt-in, no key
  └ MusixmatchLyricsProvider // opt-in, key from Keychain / xcconfig (never committed)
```

Environment:

- `LRCLIB_BASE_URL` default `https://lrclib.net`
- `MUSIXMATCH_API_KEY` from untracked xcconfig or Keychain

## Attribution

If a provider requires logo / “Lyrics by …” chrome, implement it in the **host app** first; widgets have tight space — follow the contract (some require app-level attribution only).

## What we intentionally skip

- Jailbreak hooks into system Music lyrics
- Packet-sniffing traffic from Spotify / Apple Music / Musixmatch apps
- Shipping scraped databases inside the repo
