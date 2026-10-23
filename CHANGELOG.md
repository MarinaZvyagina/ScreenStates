# Changelog

All notable changes to this project are documented in this file.
Versioning follows [Semantic Versioning](https://semver.org/) (`major.minor.patch`).

## [1.67.0]

- Add a DocC "Error Presentation" article documenting the offline-aware variant, the secondary action slot, and `ScreenStateDisplayableError`.

## [1.66.0]

- Add snapshot tests covering the offline/timeout (connectivity) variant of `ScreenStateDefaultErrorView`/`ErrorUIView` at the largest accessibility Dynamic Type size, alongside the existing standard-size coverage.

## [1.65.0]

- Add `ScreenStateDisplayableError`: a protocol letting your own error types supply a `displayMessage` distinct from `localizedDescription`. Add `ScreenState.displayMessage(for:)`, which uses it when the wrapped error conforms and falls back to `localizedDescription` otherwise. `ScreenStateDefaultErrorView`/`ErrorUIView` and `accessibilityAnnouncement` now show this instead of `error.localizedDescription` directly.

## [1.64.0]

- Add an optional `secondaryAction: (title: String, action: () -> Void)?` to `ScreenStateDefaultErrorView` and `ScreenStateDefaultErrorUIView`: a second button (e.g. "Go Back") alongside Retry. Hidden by default, so existing call sites are unaffected.

## [1.63.0]

- Add `ScreenState.isConnectivityError(_:)`: `true` for a `URLError`
  indicating no connectivity (`.notConnectedToInternet`,
  `.networkConnectionLost`) or a timed-out request (`.timedOut`).
  When the wrapped error qualifies, the default Error placeholders
  swap their icon for a Wi-Fi-specific one and (SwiftUI only — UIKit's
  Error placeholder has no separate title slot) their title for
  "Connection Issue" (localized English + Russian) instead of
  "Something Went Wrong". Every other error, including other
  `URLError` codes, keeps the generic treatment.
  `ScreenState.accessibilityAnnouncement` reflects the same
  distinction. Additive API; no source changes needed at existing
  call sites.

## [1.62.0]

- Add a "SwiftUI & UIKit Equivalents" DocC article matching every
  SwiftUI type to its UIKit counterpart in one table, including the
  handful with no equivalent (and why). Linked from the module's
  Topics page, both Getting Started articles, and README's
  Documentation section. No source or API changes.

## [1.61.0]

- Add `ScreenStateContainerViewDelegate`, reporting a bound store's
  `isRefreshing`/`refreshError` changes — the UIKit counterpart to a
  SwiftUI view reading them directly in its `body`. Set
  `ScreenStateContainerView.delegate`, or, for `ScreenStateViewController`
  subclasses, just override the new `open` `isRefreshingDidChange(_:)`/
  `refreshErrorDidChange(_:)` hooks (it already conforms to the
  delegate for you). Additive API; no source changes needed at
  existing call sites.

## [1.60.0]

- Fix `ScreenStateContainerView.bind(to:)`: calling it a second time
  with a different store left the previous store's observation
  subscription alive, so a later change on the *old* store could
  overwrite `state` with stale data even after rebinding — e.g.
  reusing a container across cells. Rebinding now immediately
  reflects the new store and stops reacting to the previous one. No
  API changes.

## [1.59.0]

- Add a regression test locking in that `observeStateChanges(of:screen:)`
  already tracks `loadCollection(_:)`/`refreshCollection(_:)` transitions
  the same way as `load(_:)`/`refresh(_:)`. No source or API changes —
  it watches `state` generically, not which method changed it.

## [1.58.0]

- Add `ScreenAnalyticsEvent.screenRetryTapped(screen:)` and
  `ScreenAnalyticsService.trackRetryTapped(_:)`, so analytics can
  distinguish a user tapping Retry from a screen's initial open —
  call it from the same `onRetry` closure passed to the Error
  placeholder. Additive API; no source changes needed at existing
  call sites.

## [1.57.0]

- Add a regression test locking in that `refresh(_:)`'s success path
  clears a stale `refreshError` left by a previous failed `refresh(_:)`
  call. No source or API changes — `refresh(_:)` already cleared
  `refreshError` unconditionally at the start of every call.

## [1.56.0]

- Add `.github/RELEASING.md` documenting the tag/publish process —
  matches the existing tag history's style (annotated `vX.Y.Z` tags
  with a `Highlights:` summary), and clarifies that a `CHANGELOG.md`
  version bump doesn't itself cut a release. Linked from
  `CONTRIBUTING.md`. No source or API changes.

## [1.55.0]

- Add a "Used By" section to README inviting adopters to add
  themselves via PR. No source or API changes.

## [1.54.0]

- Add `SECURITY.md` with a responsible-disclosure contact (GitHub
  private vulnerability reporting, with an email fallback), linked
  from `CONTRIBUTING.md`. No source or API changes.

## [1.53.0]

- Add `CODE_OF_CONDUCT.md` (Contributor Covenant v2.1), linked from
  `CONTRIBUTING.md`. No source or API changes.

## [1.52.0]

- Add `ScreenStatesDemoUITests`, an XCUITest driving the Demo app's
  Rey tab through its real auto-cycle, asserting all four `ScreenState`
  cases occur — an integration-level check the package's own unit
  suite can't give, since it never assembles `ScreenStateStore` and
  the default placeholders into a real screen inside a real app.
  `ScreenStatesDemoApp` gained a `-UITesting` launch-argument check
  that disables its own hands-off auto-tab-switching, so the test
  isn't carried away from the tab it's watching. Demo-only; no
  package source or API changes. See `Demo/ScreenStatesDemo/README.md`.

## [1.51.0]

- Add tests locking in `ScreenState.map`/`flatMap`'s functor/monad
  composition laws (identity, associativity) across all four cases,
  so a future change can't quietly break their semantics. No source
  or API changes — `map`/`flatMap` already satisfied these laws.

## [1.50.0]

- `ScreenStateStore.setData(_:)` now skips reassigning `state` when
  `Value: Equatable` and the new value equals the current `.data`
  payload, avoiding a redundant `@Observable` invalidation (and the
  unnecessary re-render that comes with it). Additive, conditional
  overload — existing `setData(_:)` call sites where `Value` isn't
  `Equatable` are unaffected.

## [1.49.0]

- Add a `.swift-format` config and a blocking CI lint step
  (`swift format lint`, bundled with the Swift 6 toolchain — no new
  dependency) to keep style consistent across contributions. Reformat
  the existing source/tests to match (trailing commas, line-break
  placement, spacing — no semantic changes). See `CONTRIBUTING.md`. No
  API changes.

## [1.48.0]

- Add a CI job matrix testing against the last two GA Xcode versions
  installed on the runner, alongside the existing default-Xcode `test`
  job — a real, blocking check, unlike the `continue-on-error` Xcode
  beta canary. Catches a regression that only shows up on an older
  still-supported Xcode before a new major Xcode ships. See
  `CONTRIBUTING.md`. No source or API changes.

## [1.47.0]

- Add a "Styling" DocC article covering the `.compact` placeholder
  style, the shimmer and redacted alternative Loading placeholders,
  and `ScreenStatesTheme` in one place. Linked from the module's
  Topics page and README's Documentation section. No source or API
  changes.

## [1.46.0]

- Add `ScreenStateRedactedLoadingView`, an opt-in Loading placeholder
  that renders your real content view through SwiftUI's
  `.redacted(reason: .placeholder)` instead of a generic spinner or
  skeleton — so the placeholder mirrors the exact shape of the content
  it's standing in for. No UIKit equivalent: `redacted(reason:)` is a
  SwiftUI-only modifier. Additive, opt-in API.

## [1.45.0]

- Add `ScreenStatesTheme` and `View.screenStatesTheme(_:)`, an
  environment-based configuration point for the default SwiftUI
  placeholders (including `ScreenStateShimmerLoadingView`): `tint`
  replaces the built-in gradient with a solid color, and
  `titleFont`/`messageFont` replace the title and message/description
  text's font, so an app can theme every default placeholder at once
  instead of passing a custom view at every call site. Increase
  Contrast still wins over `tint`. No UIKit equivalent — UIKit has no
  inherited environment, so the UIKit default placeholders keep taking
  configuration directly through their initializers. Additive API; no
  source changes needed at existing call sites.

## [1.44.0]

- Add `ScreenStateShimmerLoadingView`/`ScreenStateShimmerLoadingUIView`,
  an opt-in alternative Loading placeholder: a pulsing skeleton of a
  circular avatar plus two text-line placeholders, instead of the
  default spinner. Respects Reduce Motion (the pulse stops instead of
  animating) and Increase Contrast (a more visible gray fill), the same
  way the default placeholders do.
  `ScreenStateDefaultLoadingView`/`ScreenStateDefaultLoadingUIView`
  remain the default shown by every default-wired container; this is
  additive, opt-in API only.

## [1.43.0]

- Add `ScreenStatePlaceholderStyle` (`.standard`/`.compact`) and a
  `style:` parameter to every default placeholder (SwiftUI and UIKit).
  `.compact` sizes the icon and text down and — for the Loading
  spinner — stops forcing itself to fill all available space, so the
  same placeholder fits inside a card or section instead of taking over
  the whole screen. `.compact` always keeps a vertical icon-above-text
  layout regardless of device orientation. Additive API: every existing
  initializer keeps its old default (`style: .standard`), so no source
  changes needed.

## [1.42.0]

- Add a `continue-on-error` CI job that runs the test suite against the
  newest Xcode already on the runner image — the beta, once one ships
  ahead of the next GA release — as an early warning for upcoming
  toolchain breakage. Never blocks a PR; see `CONTRIBUTING.md`. No source
  or API changes.

## [1.41.0]

- Tune the default Empty/Error placeholders for a compact-height
  (landscape iPhone) layout: the icon now lays out beside the
  title/message/Retry column instead of above it, so large Dynamic Type
  sizes no longer risk clipping content that used to assume a
  portrait-sized column. UIKit's `UIStackView` switches `axis` between
  `.vertical` and `.horizontal` based on `traitCollection.verticalSizeClass`
  (including live updates via `traitCollectionDidChange(_:)`); SwiftUI
  builds an analogous horizontal layout directly, since
  `ContentUnavailableView` has no configuration point for this, driven by
  the `verticalSizeClass` environment value (iOS/iPadOS/Mac Catalyst
  only). No API changes.

## [1.40.0]

- Tune the default placeholders for Mac Catalyst: the icon and loading
  spinner are sized down a bit (48pt/36pt instead of 56pt/44pt), since a
  Mac window is driven by a precise pointer rather than a touch target
  that needs to stay comfortably tappable, and the SwiftUI Retry button
  now shows a deliberate `.hoverEffect(.highlight)` instead of leaving
  it to whatever `.automatic` resolves to (UIKit's `UIButton` already
  gets pointer hover for free). No API changes.

## [1.39.0]

- Add an "Accessibility" DocC article rounding up VoiceOver, Reduce
  Motion, Increase Contrast, Dynamic Type, and the default placeholders'
  stable identifiers in one place. Linked from the module's Topics page
  and README's Documentation section. No source or API changes.

## [1.38.0]

- Add `ScreenState.accessibilityAnnouncement`, exposing the same text the
  default placeholders announce to VoiceOver per case — `nil` for
  `.data`, the default "Nothing Here" title for `.empty`, `"Loading"`
  for `.loading`, and the error's localized description (prefixed with
  "Something Went Wrong") for `.error` — so a fully custom placeholder
  can announce transitions with the same wording instead of inventing
  its own. The default Error placeholders (SwiftUI and UIKit) now
  compute their own announcement through this property instead of
  duplicating the format string.

## [1.37.0]

- Add Dynamic Type snapshot tests at the largest accessibility text size
  for all six default placeholders. Along the way,
  `ScreenStateDefaultEmptyUIView`/`ErrorUIView` now compute their label's
  font via the explicit `UIFont.preferredFont(forTextStyle:compatibleWith:)`
  overload instead of the no-argument one, so it's driven by the view's
  own trait collection rather than only the ambient app-wide setting —
  the no-argument overload doesn't vary with a view-specific trait
  collection, which is what made this untestable in isolation to begin
  with. No public API changes.

## [1.36.0]

- The three default placeholders' gradient icons/ring now respect
  Increase Contrast: `ScreenStateDefaultEmptyView`/`ErrorView`/`LoadingView`
  read SwiftUI's `colorSchemeContrast` environment value, and
  `ScreenStateDefaultEmptyUIView`/`ErrorUIView`/`LoadingUIView` read
  `UIAccessibility.isDarkerSystemColorsEnabled` (and observe it live, so
  an already-visible placeholder responds immediately if the setting
  changes while on screen) — they fall back to a solid `.label`/`.primary`
  tint instead of a gradient. No API changes.

## [1.35.0]

- The default Loading placeholder now respects Reduce Motion:
  `ScreenStateDefaultLoadingView` reads SwiftUI's `accessibilityReduceMotion`
  environment value, and `ScreenStateDefaultLoadingUIView` reads
  `UIAccessibility.isReduceMotionEnabled` (and observes it live, so an
  already-visible spinner responds immediately if the setting changes
  while on screen) — the ring stays static instead of spinning. No API
  changes.

## [1.34.0]

- Add a "Concurrency & Cancellation" DocC article consolidating
  `ScreenStateStore`'s overlapping-call, `cancel()`, deinit, and
  `reset(to:)` guarantees in one place. Linked from the module's Topics
  page and README's Documentation section. No source or API changes.

## [1.33.0]

- Add `ScreenStateStore.reset(to:)`, to snap a store back to `.loading`
  (or any given state) outside of a `load`/`refresh` call — useful for a
  full sign-out/reset flow. Cancels whatever operation is currently in
  flight (as `cancel()` does) and clears `isRefreshing`/`refreshError`,
  so nothing stale can land and overwrite `state` after the reset.

## [1.32.0]

- `ScreenStateStore` now cancels its own in-flight task from `deinit`,
  mirroring `cancel()`, as a last-resort safety net in case one is ever
  still tracked by the time the store is deallocated. In practice
  `load`/`refresh`/etc. already await their own task to completion
  before returning, so this normally has nothing left to do by the time
  `deinit` runs — it guards against that assumption changing later, for
  free. No API changes.

## [1.31.0]

- Add `ScreenStateStore.cancel()`, to explicitly stop whatever `load`/
  `loadCollection`/`refresh`/`refreshCollection`/`loadWithRetry` call is
  currently in flight — useful from `onDisappear`, or right before
  firing off a newer query. `state` (and `isRefreshing`/`refreshError`)
  are left exactly as they were; cancelling never surfaces a
  `CancellationError` through `state`. As part of this, `operation` is
  now run in a `ScreenStateStore`-owned `Task` that `cancel()` can
  target, rather than directly in the caller's own task. Also: a
  behavior change for `loadWithRetry(_:)` — cancelling it while it's
  waiting between retries now leaves `state` untouched instead of
  settling into `.error` with a `CancellationError`, matching every
  other call's cancellation behavior.

## [1.30.0]

- Fix a race in `ScreenStateStore`: if `load(_:)`/`loadCollection(_:)`/
  `refresh(_:)`/`refreshCollection(_:)`/`loadWithRetry(_:)` overlap — a
  second call starting before an earlier one has finished — a slow, now-
  stale response landing late could previously overwrite state a newer
  call already produced. Each call now tracks a generation token and
  drops its own result if a newer call has since started, instead of
  applying it. `refresh(_:)`/`refreshCollection(_:)`'s `isRefreshing`
  also now stays `true` until the newest in-flight refresh finishes,
  rather than being cleared by whichever overlapping refresh happens to
  resolve first. No API changes — purely a correctness fix.

## [1.29.0]

- Add `.spi.yml`, telling the [Swift Package Index](https://swiftpackageindex.com/MarinaZvyagina/ScreenStates)
  to build the `ScreenStates` target's documentation, and add Swift-versions
  and platform-compatibility SPI badges plus an "also listed on the Swift
  Package Index" link to README. Submitting the repository URL at
  [swiftpackageindex.com/add-a-package](https://swiftpackageindex.com/add-a-package)
  is a one-time manual step outside this repo — the badges above will read
  as "not yet indexed" until that's done. No source changes.

## [1.28.0]

- Add a "Recipes" DocC article covering three common multi-screen
  patterns built on `ScreenStateStore`: list + detail (a pushed detail
  screen with its own store, using `.task(id:)` so it's reusable where
  the same instance's ID can change instead of being recreated), one
  store per tab (relying on `TabView`'s view-identity preservation to
  avoid reloading on every switch), and master-detail with
  `NavigationSplitView` (reusing the same detail screen from list +
  detail, since its `.task(id:)` handles a changing selection on the
  same instance). Linked from the module's Topics page and README's
  Documentation section. No source or API changes.

## [1.27.0]

- Add `CONTRIBUTING.md` (build/test commands, commit conventions, what a
  feature-level PR needs to update) plus GitHub issue templates (bug
  report, feature request) and a pull request template, so a contributor
  gets the same checklist a maintainer already follows. No source
  changes.

## [1.26.0]

- Add `loadWithRetry(maxAttempts:backoff:_:)` to `ScreenStateStore`, for
  operations worth retrying automatically before giving up — a flaky
  network call, for example. Like `load(_:)`, but retries a failing
  `operation` up to `maxAttempts` times, keeping `state` at `.loading`
  across every attempt; only the final failure switches it to `.error`.
  `backoff` is called with the attempt number that just failed (`1`, `2`,
  …) and returns how long to wait before the next try, defaulting to
  doubling from one second. If the wait itself is cancelled, `state`
  becomes `.error` with the cancellation error instead of retrying
  further. Purely additive alongside `load(_:)`.

## [1.25.0]

- Add `ScreenAnalyticsEvent.screenLoadDuration(screen:outcome:milliseconds:)`
  and have `ScreenAnalyticsService.observeStateChanges(of:screen:)` send one
  automatically every time a store's `.loading` span ends — `outcome` is the
  resulting state's `analyticsKind` (`"data"`, `"empty"`, or `"error"`) and
  `duration_ms` the elapsed time, measured with `ContinuousClock` so it's
  unaffected by wall-clock adjustments. If a store is already `.loading`
  when `observeStateChanges(of:screen:)` is called (the common case, since
  `ScreenStateStore()` defaults to `.loading`), the clock starts then rather
  than waiting for a transition *into* `.loading` that will never come.
  Purely additive — existing `screen_state_changed` events are unchanged,
  this is a new event alongside them.

## [1.24.0]

- Add a `docs` job to `.github/workflows/tests.yml` that runs `xcodebuild
  docbuild` with `OTHER_DOCC_FLAGS="--warnings-as-errors"`, so a broken doc
  comment or symbol link fails CI instead of only showing up as a build
  warning the next time someone happens to run `Scripts/generate-docs.sh`
  locally. Turning this on surfaced three existing gaps — `store`/
  `contentProvider` on `ScreenStateViewController.init(store:onRetry:content:)`,
  `contentProvider` on `ScreenStateContainerView.init(onRetry:content:)`,
  and `state`/`content` on `ScreenStateView.init(_:onRetry:content:)` were
  undocumented once any other parameter on the same initializer was (DocC
  only enforces completeness once you've started) — now fixed. No API or
  behavior changes.

## [1.23.0]

- Fix the UIKit Empty/Error placeholders' icon rendering, which could clip
  the icon against its 56x56 box or, for the Error placeholder specifically,
  render no icon at all. The icon was previously painted by masking a
  `CAGradientLayer` with a `UIImageView` that was never added to the view
  hierarchy, so it only got a real `frame` once `layoutSubviews()` happened
  to run — a mask view with no frame yet renders nothing, and a fresh
  `ScreenStateDefaultErrorUIView` (recreated on every `.error` transition,
  unlike the reused Empty/Loading placeholders) could be composited for the
  first time before that ever happened, losing a Core Animation first-commit
  race and staying permanently blank. Both placeholders now bake the
  gradient directly into a `UIImage` up front (`sourceIn`-blended over the
  SF Symbol) and display it with a plain `UIImageView`, removing the masking
  race entirely. No API changes — `iconGradient`/`iconMask` (both internal)
  are replaced by a single internal `iconView: UIImageView`, and the
  UIKit gradient-stop regression tests now check the baked image's pixels
  instead, the same way the SwiftUI tests already did.

## [1.22.0]

- Add code coverage reporting to CI: `tests.yml` now runs with
  `-enableCodeCoverage YES` and, on pushes to `main`, updates a
  self-hosted shields.io "endpoint" badge (`.github/badges/coverage.json`,
  no external coverage service or secret needed) with the `ScreenStates`
  target's line coverage percentage, committing with `[skip ci]` to avoid
  re-triggering itself. New Coverage badge in the README. The library
  itself is unchanged.

## [1.21.0]

- Tune the default SwiftUI placeholders' sizing for watchOS's compact
  screens: the Empty/Error icon shrinks from 56pt to 28pt, and the
  Loading spinner from 44pt (4pt stroke) to 24pt (3pt stroke) — an
  iPhone-sized icon would otherwise dominate a watch display. iOS/macOS/
  tvOS/visionOS sizing is unchanged. No new public API.

## [1.20.0]

- Tune the default placeholders for tvOS's focus engine. Swapping content
  programmatically (as `ScreenStateContainerView` does on every state
  change) doesn't automatically nudge the focus engine, so the Siri
  Remote could appear stuck on a view that was just removed —
  `ScreenStateContainerView` now calls `setNeedsFocusUpdate()`/
  `updateFocusIfNeeded()` after swapping, and it, `ScreenStateViewController`,
  and the default Error placeholder (SwiftUI and UIKit) all declare a
  `preferredFocusEnvironments`/`prefersDefaultFocus` chain that sends
  focus straight to the Retry button when it's showing. No new public
  API — these are tvOS-only overrides of existing UIKit/SwiftUI focus
  hooks, guarded with `#if os(tvOS)`. The tvOS SDK isn't installed on
  this machine (see `CLAUDE.md`), so this change is based on careful API
  review rather than a real tvOS build — worth a first real run on tvOS
  hardware/simulator when the SDK is available.

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
