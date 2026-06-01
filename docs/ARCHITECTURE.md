# Architecture

## Layer Overview

```
┌──────────────────────────────────────────────────┐
│  App                                             │
│  AppDelegate · PriceTickerApp                    │
├──────────────────────────────────────────────────┤
│  Windows / Controllers                           │
│  FloatingPanel · FloatingPanelController         │
│  LeaderboardPanelController                      │
├──────────────────────────────────────────────────┤
│  Services                                        │
│  PriceService · LeaderboardService               │
│  BtcSparklineService · NetworkSession            │
├──────────────────────────────────────────────────┤
│  Models                                          │
│  Ticker · TickerStore · ProxySettings            │
├──────────────────────────────────────────────────┤
│  Views (SwiftUI)                                 │
│  PopoverContentView · AddTickerView              │
│  FloatingTagView · LeaderboardView               │
│  LeaderboardPanelView · SettingsView             │
└──────────────────────────────────────────────────┘
```

Data flows downward; Combine publishers propagate changes back up to the UI.

---

## Key Design Decisions

### NSPanel subclass for floating windows

`FloatingPanel` subclasses `NSPanel` (not `NSWindow`). The panel uses the
`.nonactivatingPanel` style mask so clicking a price tag never steals focus
from the user's active app. `isFloatingPanel = true` and `level = .floating`
keep tags visible above normal windows. `collectionBehavior` includes
`.canJoinAllSpaces` so tags appear on every Space and in full-screen mode.

`resetCursorRects()` is overridden to call `discardCursorRects()` before
adding an arrow cursor rect for the entire content view, preventing SwiftUI's
internal views from substituting a resize or text cursor.

### NSHostingController instead of NSHostingView

`FloatingPanelController` and `LeaderboardPanelController` both embed SwiftUI
via `NSHostingController` set as the panel's `contentViewController`. Using
`NSHostingController` (rather than `NSHostingView` as the `contentView`)
is required because it correctly integrates with the AppKit view controller
lifecycle, which allows `@ObservedObject` observation to work reliably inside
the hosted SwiftUI view tree.

### FloatingPanel.sendEvent manual event loop for drag vs tap

`FloatingPanel` overrides `sendEvent(_:)` to implement its own mini event loop
that reads `leftMouseDragged` / `leftMouseUp` events directly from the queue
(`NSApp.nextEvent(matching:...)`). A 4-point threshold distinguishes a drag
from a tap; `onMoved` and `onTap` callbacks are invoked accordingly. This is
necessary because the panel is borderless — AppKit would not otherwise produce
drag tracking.

### Adaptive backoff on network failure

All three polling services (`PriceService`, `LeaderboardService`,
`BtcSparklineService`) implement exponential backoff independently. On each
consecutive failure the timer interval doubles up to a service-specific cap:

| Service | Normal | Cap |
|---------|--------|-----|
| PriceService | 5 s | 30 s |
| LeaderboardService | 30 s | 300 s |
| BtcSparklineService | 300 s | 2400 s |

Any successful response resets the streak and restarts the timer at the normal
rate. `NetworkStatus` wraps a single `NWPathMonitor` shared by all polling
services; when connectivity is lost, active timers stop and in-flight requests
are cancelled, then backoff resets and polling resumes when connectivity is
restored.

### NetworkSession class with rebuild()

`NetworkSession` is a `final class` singleton (not an enum). Its inner
`URLSession` is rebuilt whenever `ProxySettings.shared.apply(...)` is called.
All services hold a reference to `NetworkSession.shared` (a reference type),
so calling `dataTaskPublisher(for:)` always forwards to the current session —
no service code needs to change when proxy settings change at runtime.

### ProxySettings — UI-configurable proxy

`ProxySettings` is a `UserDefaults`-backed `ObservableObject`. The user opens
the settings sheet in the popover, toggles the proxy switch, and enters host +
port. Pressing **Save** calls `ProxySettings.shared.apply(...)`, which persists
the values, rebuilds `NetworkSession`, and posts a notification so active
services can reset backoff and retry immediately with the new session.

### Per-ticker AnyCancellable dict to prevent in-flight request leaks

`PriceService` maintains `private var fetchTasks: [UUID: AnyCancellable]`.
Assigning a new value to `fetchTasks[ticker.id]` automatically cancels the
previous in-flight publisher for that ticker, preventing stale responses from
overwriting current data when a fetch takes longer than the poll interval.

### LeaderboardPanelController replaces rootView to trigger re-render

`LeaderboardPanelController` holds a reference to the `NSHostingController`
and replaces `hostingController.rootView` when `showGainers` flips (via
`$showGainers.dropFirst().sink`). A manual `Binding` created with a closure
is not reactive — SwiftUI will not re-render when the underlying `@Published`
property changes unless the view observes the object directly. Replacing
`rootView` is the most direct way to force a re-render across the
panel/controller boundary without adding a circular reference.

### LeaderboardEntry stable ID

`LeaderboardEntry.id` is computed from `symbol` (a `String`) rather than
a new `UUID()` on every `process()` call. This prevents SwiftUI's `ForEach`
from treating every 30-second leaderboard refresh as a full row replacement,
which would cause unnecessary animations and view recycling.

---

## Data Flow Summary

```
Binance REST API
    │
    ▼
PriceService ──$prices──► FloatingTagView (per tag)
    │
    └─$isConnected/$lastUpdated──► AppDelegate (status dot)

BtcSparklineService ──$prices──► AppDelegate (sparkline icon + tooltip)

LeaderboardService ──$topGainers/$topLosers──► LeaderboardView
                                            └► LeaderboardPanelView

TickerStore ──$tickers──► FloatingPanelController (open/close panels)
                       └► PopoverContentView (watchlist rows)

ProxySettings ──apply()──► NetworkSession.rebuild()
```

---

## File Map

```
PriceTicker/                  Project root
├── project.yml               XcodeGen spec
├── PriceTicker.xcodeproj/    Generated Xcode project
├── scripts/
│   └── bootstrap.sh          One-command setup
├── docs/
│   ├── ARCHITECTURE.md       This file
│   └── DEVELOPMENT.md        Developer workflow
├── README.md
├── CHANGELOG.md
└── PriceTicker/              Swift source root
    ├── App/
    │   ├── AppDelegate.swift         Menu bar, popover, sparkline icon
    │   └── PriceTickerApp.swift      SwiftUI App entry point
    ├── Models/
    │   ├── ProxySettings.swift       UserDefaults-backed proxy config; triggers session rebuild
    │   ├── Ticker.swift              Codable value type: symbol, market, window position
    │   └── TickerStore.swift         ObservableObject; CRUD + UserDefaults persistence
    ├── Services/
    │   ├── BtcSparklineService.swift 24 × 1h klines for menu bar sparkline; refreshes every 5 min
    │   ├── LeaderboardService.swift  Visible-only all-symbol 24hr ticker; extracts top-5 gainers/losers
    │   ├── NetworkSession.swift      Shared URLSession and NetworkStatus
    │   └── PriceService.swift        Per-ticker 24hr poll every 5 s; shared connectivity; backoff
    ├── Views/
    │   ├── AddTickerView.swift       Symbol input + preset grid inside the popover
    │   ├── FloatingTagView.swift     Price tag pill: price + 24h change %
    │   ├── LeaderboardPanelView.swift  Compact gainers/losers list for the floating panel
    │   ├── LeaderboardView.swift     Full gainers/losers list in the popover
    │   ├── PopoverContentView.swift  Main popover: Top 5 (default) + Watchlist tabs
    │   └── SettingsView.swift        Proxy settings sheet (toggle + host/port fields)
    ├── Windows/
    │   ├── FloatingPanel.swift            NSPanel subclass; drag/tap event loop; arrow cursor
    │   ├── FloatingPanelController.swift  Creates/destroys panels; syncs with TickerStore
    │   └── LeaderboardPanelController.swift  Single leaderboard panel; showGainers toggle
    ├── Assets.xcassets/          App icon (1024 × 1024 CoreGraphics-generated PNG)
    ├── Info.plist
    └── PriceTicker.entitlements
```
