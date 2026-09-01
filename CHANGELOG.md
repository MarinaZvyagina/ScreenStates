# Changelog

All notable changes to this project are documented in this file.
Versioning follows [Semantic Versioning](https://semver.org/) (`major.minor.patch`).

## [1.6.0]

- Add an analytics layer: `ScreenAnalyticsTracker`, a protocol you implement
  once per analytics backend (Firebase, Mixpanel, Amplitude, your own
  endpoint, ...) to convert a backend-agnostic `ScreenAnalyticsEvent` (name +
  `[String: AnalyticsValue]` parameters) into that SDK's own format;
  `ScreenAnalyticsService`, which fans events out to every registered
  tracker via `track(_:)`, sends a `screen_opened` event via
  `trackScreenOpened(_:source:)`, and can automatically send a
  `screen_state_changed` event for every subsequent `ScreenState` transition
  on a store via `observeStateChanges(of:screen:)` (using the same
  `withObservationTracking` mechanism as `ScreenStateContainerView`). Also
  adds `ScreenState.analyticsKind` and `ScreenOpenSource.analyticsKind`
  helpers. ScreenStates ships no concrete tracker implementations, so the
  library stays dependency-free.

## [1.5.0]

- Add `refresh(_:)` and `refreshCollection(_:)` to `ScreenStateStore`, for
  the pull-to-refresh case: unlike `load(_:)`/`loadCollection(_:)`, they
  keep whatever is currently in `state` on screen while the operation runs
  (`isRefreshing` reports the in-flight status) and leave it there on
  failure instead of switching to `.error`, reporting the failure via the
  new `refreshError` property instead. Both fall back to
  `load(_:)`/`loadCollection(_:)` when there's no data yet to preserve. No
  changes to `ScreenState` itself — purely additive on the store.

## [1.4.0]

- Rework the demo app's content: the SwiftUI screen now shows Rey Skywalker
  facts, the UIKit screen shows Kylo Ren facts (each with a lightsaber-color
  accent), replacing the generic Articles/Tasks placeholders. No character
  artwork is used — SF Symbols and text only. The library itself is
  unchanged.

## [1.3.0]

- Add `ScreenOpenSource<Screen>`, an independent type modeling how a screen
  came to be visible (`.push`/`.pop`/`.presented(from:)`, `.deepLink(URL)`,
  `.shortcut(id:)`, `.tabSelection`, `.unknown`), with `isPop` and
  `originatingScreen` helpers, so a screen can change its behavior (e.g.
  skip a reload on `.pop`) based on it. Apps supply the value themselves —
  the library can't detect navigation on its own.

## [1.2.0]

- Add a DocC documentation site (module landing page + Getting Started
  articles for SwiftUI and UIKit), published via GitHub Pages at
  https://marinazvyagina.github.io/ScreenStates/documentation/screenstates/.
  Regenerate it with `Scripts/generate-docs.sh`. The library itself is
  unchanged.

## [1.1.0]

- Add `Demo/ScreenStatesDemo`, a runnable two-screen app (SwiftUI + UIKit)
  that cycles through all four states via the library's real
  `loadCollection(_:)` API, with a recorded GIF embedded in the README.
  The library itself is unchanged.

## [1.0.1]

- Add stable `accessibilityIdentifier`s (`screenStates.loading`, `screenStates.empty`,
  `screenStates.error`, `screenStates.error.retryButton`) to every default SwiftUI and
  UIKit placeholder view, so consuming apps can reliably target them from XCUITest.

## [1.0.0]

- Initial release: `ScreenState<Value>`, `ScreenStateStore<Value>`, SwiftUI's
  `ScreenStateView`, and UIKit's `ScreenStateContainerView`, with default
  Empty / Loading / Error placeholders for both paradigms.
