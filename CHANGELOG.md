# Changelog

All notable changes to this project are documented in this file.
Versioning follows [Semantic Versioning](https://semver.org/) (`major.minor.patch`).

## [1.19.0]

- Broaden `Package.swift`'s `platforms` from iOS-only to iOS 17+, macOS
  14+, tvOS 17+, watchOS 10+, and visionOS 1+ (matching the Observation
  framework's own minimums). `ScreenState`, `ScreenStateStore`, the
  SwiftUI views, and the Analytics module now work on all five;
  `ScreenStateContainerView`/`ScreenStateViewController` stay iOS/tvOS/
  visionOS-only, since their existing `#if canImport(UIKit) && !os(watchOS)`
  guard already correctly excludes both watchOS and macOS. The library
  sources needed no other changes — but this surfaced two test files
  (`PlaceholderVisualTests.swift`, `ScreenStateViewControllerTests.swift`)
  with an unconditional `import UIKit` (and, for the former, SwiftUI
  helpers using `UIImage`/`ImageRenderer.uiImage`, unavailable on macOS),
  now fixed with the same guard. `swift build`/`swift test` work directly
  on macOS as of this change; tvOS/watchOS/visionOS SDKs aren't installed
  on this machine, so those three weren't independently compiled — a good
  candidate for CI to verify going forward.

## [1.18.0]

- Add `ScreenState.map(_:)` and `flatMap(_:)` to transform a `.data`
  payload without manually switching over every other case first — the
  same idea as `Optional.map`/`Optional.flatMap`. Every other case
  (`.empty`, `.loading`, `.error`) passes through untouched; `flatMap(_:)`
  lets the transform itself produce a different case, e.g. `.empty` after
  filtering a collection down to nothing.

## [1.17.0]

- Add `ScreenStateViewController<Value>`, a `UIViewController` base class
  that owns a `ScreenStateContainerView` pinned to the view's edges and
  bound to a `ScreenStateStore`, wrapping the `viewDidLoad()` boilerplate
  every UIKit screen using ScreenStates otherwise repeats. Mirrors
  `ScreenStateContainerView`'s own two initializers (default placeholders,
  or fully customized).

## [1.16.0]

- Add `View.screenState(_:onRetry:content:)`, a view-modifier alternative
  to constructing `ScreenStateView` directly, plus a matching overload for
  the fully-customized empty/loading/error initializer. Pure sugar — both
  just build a `ScreenStateView` under the hood.

## [1.15.0]

- Add `ScreenStateStore` factories for SwiftUI Previews: `preview(_:)`
  pins a store to any `ScreenState`, and `previewLoading`, `previewEmpty`,
  `previewData(_:)`, `previewError(_:)` cover the four cases by name.
  `previewError(_:)` uses a new `ScreenStatePreviewError` so a preview
  doesn't need a placeholder `Error` type of its own.

## [1.14.0]

- Add `PrintScreenAnalyticsTracker` (logs every event to the console) and
  `NoOpScreenAnalyticsTracker` (silently discards every event) as
  ready-made `ScreenAnalyticsTracker`s for quick debugging, tests, and
  Previews, so you don't have to hand-roll a console logger yourself. Also
  add `AnalyticsValue: CustomStringConvertible` for readable console
  output.

## [1.13.0]

- Add regression tests protecting all six default placeholders' gradient
  treatment: the SwiftUI ones render to a `UIImage` via `ImageRenderer`
  and assert at least one pixel is clearly colorful (avoiding the
  cross-Xcode-version flakiness of exact pixel-for-pixel snapshot
  comparison); the UIKit ones check the underlying `CAGradientLayer`
  stops directly, since this package's test target has no live
  window/scene to render a `UIView` hierarchy into. Two UIKit internals
  (`GradientUIView` and the placeholders' `iconGradient`/`gradientRing`
  properties) moved from `private` to internal so `@testable import`
  tests can reach them — no public API changes.

## [1.12.0]

- Localize the default placeholders' text (English + Russian) via a String
  Catalog (`Resources/Localizable.xcstrings`), resolved from the package's
  own `Bundle.module` so a custom `title` an app passes in is never run
  back through localization. The resolved strings are exposed as public
  `String` statics (`screenStatesLoading`, `screenStatesNothingHere`,
  `screenStatesSomethingWentWrong`, `screenStatesRetry`) since they're used
  as default argument values in the placeholders' public initializers.

## [1.11.0]

- Announce every state transition to VoiceOver from the default Empty,
  Loading, and Error placeholders — an `AccessibilityNotification.Announcement`
  in SwiftUI, `UIAccessibility.post(notification: .announcement, ...)` in
  UIKit — so a screen reader user learns the screen went from Loading to
  Data/Empty/Error without having to explore the screen first. No API
  changes.

## [1.10.0]

- Give the default Error placeholder (`ScreenStateDefaultErrorView` in
  SwiftUI, `ScreenStateDefaultErrorUIView` in UIKit) a bigger triangle icon
  rendered with a warm red/orange gradient, replacing the plain gray
  system-image tint (SwiftUI) and the icon-less layout (UIKit) — matching
  the gradient treatment the Empty and Loading placeholders already have.
  No API changes.

## [1.9.0]

- Give the default Loading placeholder (`ScreenStateDefaultLoadingView` in
  SwiftUI, `ScreenStateDefaultLoadingUIView` in UIKit) the same vibrant
  gradient treatment as the Empty placeholder: a spinning ring stroked with
  a pink/orange/yellow angular gradient, replacing the plain gray
  `ProgressView`/`UIActivityIndicatorView`. No API changes — both still
  have a parameterless `init()`.

## [1.8.0]

- Give the default Empty placeholder (`ScreenStateDefaultEmptyView` in
  SwiftUI, `ScreenStateDefaultEmptyUIView` in UIKit) a bigger icon rendered
  with a vibrant pink/orange/yellow gradient, replacing the plain gray
  system-image tint (SwiftUI) and the icon-less text-only layout (UIKit).
  Both still accept the same `title`/`systemImage` parameters as before.

## [1.7.0]

- Add a GitHub Actions workflow (`.github/workflows/tests.yml`) that runs
  `xcodebuild test` against an iOS Simulator on every push to `main` and
  every pull request, plus a Tests badge in the README. The library itself
  is unchanged.

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
