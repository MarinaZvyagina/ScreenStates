# Roadmap

Small, incremental improvements to ScreenStates, one item per day, planned in batches of about a month. See `CLAUDE.md` for how these get picked up and shipped.

## Week 1 — Visual consistency

- [x] Give `ScreenStateDefaultLoadingView`/`ScreenStateDefaultLoadingUIView` the same vibrant gradient treatment the Empty placeholder got, instead of a plain gray spinner.
- [x] Give `ScreenStateDefaultErrorView`/`ScreenStateDefaultErrorUIView` a warm red/orange gradient icon, consistent with the Empty and Loading placeholders.
- [x] Announce state transitions to VoiceOver (`UIAccessibility.post` in UIKit, an `AccessibilityNotification` in SwiftUI) from the default placeholders.
- [x] Localize the three default placeholder texts via a String Catalog (`Localizable.xcstrings`), starting with English + Russian.
- [x] Add snapshot/regression tests for all six default placeholder views (SwiftUI + UIKit) to protect the new visuals going forward.

## Week 2 — Developer ergonomics

- [x] Ship `PrintScreenAnalyticsTracker` and `NoOpScreenAnalyticsTracker` as ready-made `ScreenAnalyticsTracker`s for quick debugging and tests.
- [x] Add `ScreenStateStore` factory helpers for SwiftUI Previews (e.g. a store pinned to a fixed `ScreenState`).
- [x] Add a SwiftUI `.screenState(_:onRetry:content:)` view modifier as sugar alongside `ScreenStateView`.
- [x] Add a UIKit `ScreenStateViewController` base class wrapping the `ScreenStateContainerView` + `bind(to:)` boilerplate.
- [x] Add `ScreenState.map`/`flatMap` to transform the wrapped value without manually unwrapping `.data`.

## Week 3 — Platform reach & infrastructure

- [x] Broaden `Package.swift`'s `platforms` to macOS/tvOS/watchOS/visionOS, auditing every `#if canImport` guard.
- [x] Tune the default Loading/Empty placeholders for tvOS's focus engine.
- [x] Tune default placeholder sizing/typography for watchOS's compact screens.
- [x] Add code coverage reporting to CI, plus a coverage badge in the README.
- [x] Add a CI check that builds the DocC catalog, so broken doc comments/links fail the build.

## Week 4 — Analytics depth & community health

- [x] Track screen load duration (`.loading` → `.data`/`.error` elapsed time) as a new `ScreenAnalyticsEvent`.
- [x] Add `loadWithRetry(maxAttempts:backoff:)` to `ScreenStateStore` for automatic retry with backoff.
- [x] Add `CONTRIBUTING.md` plus issue/PR templates.
- [x] Add a DocC "Recipes" article covering common patterns (list + detail, one store per tab, master-detail).
- [x] Publish to the Swift Package Index (`.spi.yml`) and add an SPI badge to the README.

## Week 5 — Resilience & concurrency safety

- [x] Guard `load(_:)`/`loadCollection(_:)`/`refresh(_:)`/`refreshCollection(_:)`/`loadWithRetry(_:)` against a stale operation resolving after a newer one already started — check for that race and drop the stale result instead of letting it overwrite fresher state.
- [x] Add `ScreenStateStore.cancel()` to explicitly cancel whatever `load`/`refresh` operation is currently in flight, keeping `state` as-is.
- [x] Cancel a `ScreenStateStore`'s in-flight operation automatically on `deinit`, so a torn-down screen's stale response can never run after the store it would have mutated is already gone.
- [x] Add `ScreenStateStore.reset(to:)` to snap a store back to `.loading` (or any given state) outside of a `load` call — useful for a full sign-out/reset flow.
- [x] Add a DocC "Concurrency & Cancellation" article documenting the guarantees above.

## Week 6 — Accessibility depth

- [x] Respect Reduce Motion for the default Loading spinner's animation (`accessibilityReduceMotion` in SwiftUI, `UIAccessibility.isReduceMotionEnabled` in UIKit).
- [x] Respect Increase Contrast for the gradient Empty/Loading/Error icons, falling back to a solid high-contrast tint.
- [x] Add Dynamic Type snapshot tests at the largest accessibility text sizes for all six default placeholders.
- [x] Expose a stable, reusable VoiceOver announcement string per `ScreenState` case (not just baked into the default placeholders), so fully custom placeholders can announce transitions with the same wording.
- [x] Add a DocC "Accessibility" article rounding up VoiceOver, Reduce Motion, Increase Contrast, Dynamic Type, and identifiers in one place.

## Week 7 — Platform & environment polish

- [x] Tune the default placeholders for Mac Catalyst (pointer/hover states, typography sized for a mouse-driven window rather than touch).
- [x] Tune the default placeholders for landscape / compact-height iPhone layouts, which currently assume a portrait-sized column.
- [ ] Tune the default placeholders for visionOS (ornaments/depth), which currently just inherit the iOS layout as-is.
- [x] Add a CI job that builds against the latest Xcode beta with `continue-on-error`, to catch upcoming toolchain breakage before it ships.
- [ ] Fix the default placeholders' inset handling inside a `NavigationSplitView` detail column so they don't visually collide with the sidebar divider on iPad.

## Week 8 — Visual variety & theming

- [x] Add a "compact" style variant of the default placeholders (smaller icon/text) for embedding in a card or section rather than a whole screen.
- [x] Add a skeleton/shimmer-style Loading placeholder as an alternative opt-in built-in style.
- [x] Add an environment-based configuration point (tint/typography) so an app can theme the built-in placeholders globally instead of passing custom views at every call site.
- [x] Add a `redacted(reason: .placeholder)`-based Loading content option as an alternative to the spinner, mirroring the shape of the real content.
- [x] Add a DocC "Styling" article documenting the built-in style variants and the theming configuration point.

## Week 9 — Testing & tooling maturity

- [x] Add a CI matrix running the test suite against the last two Xcode versions, to catch regressions before a new major Xcode ships.
- [x] Add a `swift-format` (or SwiftLint) config plus a CI lint step, to keep style consistent across contributions.
- [ ] Add a regression test asserting `ScreenStateStore.setData(_:)` with an unchanged, `Equatable` payload doesn't trigger a redundant `@Observable` invalidation.
- [ ] Add an XCUITest that drives the Demo app through all four states end-to-end, catching integration regressions the unit suite can't.
- [ ] Add tests locking in `ScreenState.map`/`flatMap`'s composition laws (identity, associativity) so future changes can't quietly break their semantics.

## Week 10 — Ecosystem & community growth

- [ ] Add `CODE_OF_CONDUCT.md`.
- [ ] Add `SECURITY.md` with a responsible-disclosure contact.
- [ ] Add a GitHub Discussions Q&A category/template, linked from README, as a lighter-weight alternative to opening an issue.
- [ ] Add a "Used By" section to README inviting adopters to add themselves via PR.
- [ ] Add `.github/RELEASING.md` documenting the tag/publish process, matching the version-bump convention already used in `CHANGELOG.md`.

## Week 11 — Store ergonomics & analytics completeness

- [ ] Add a `ScreenStateStore.refreshError`-clearing path so a successful `refresh(_:)` after a failed one doesn't leave the stale error dangling once `isRefreshing` flips back to `false`.
- [ ] Add a `ScreenAnalyticsEvent` for retry taps specifically (distinct from a generic load event), so analytics can distinguish "user hit retry" from the initial load.
- [ ] Add `ScreenStateStore.loadCollection(_:)`/`refreshCollection(_:)` analytics events mirroring the ones already tracked for `load(_:)`/`refresh(_:)`.
- [ ] Add a `ScreenOpenSource`-aware convenience initializer on `ScreenStateStore` so call sites that already know their open source don't need a separate `track(openSource:)` call.
- [ ] Add a DocC code snippet (via `@Snippet`) for the retry-with-backoff recipe, replacing the current prose-only `loadWithRetry` example in the Recipes article.

## Week 12 — SwiftUI & UIKit parity

- [ ] Audit `ScreenStateView`/`ScreenStateContainerView` for a parity gap: add whichever of `.screenState(_:onRetry:content:)`'s SwiftUI conveniences (e.g. a no-retry overload) is still missing from the UIKit `ScreenStateViewController` side.
- [ ] Add a `ScreenStateView` initializer overload that takes an `EquatableValue` fast-path check (mirroring the `Equatable`-payload redundant-invalidation guard planned for `ScreenStateStore` in Week 9) to skip re-rendering identical `.data` content.
- [ ] Add a UIKit `ScreenStateContainerView` snapshot test suite covering programmatic `bind(to:)` rebinding to a different store mid-lifecycle, which only has SwiftUI coverage today.
- [ ] Expose `ScreenStateStore`'s `isRefreshing`/`refreshError` to UIKit consumers via a small delegate callback, mirroring how SwiftUI observes them through `@Observable`.
- [ ] Add a DocC article cross-referencing equivalent SwiftUI/UIKit API pairs in a single table, so a reader working in one framework can find the other's equivalent at a glance.

## Week 13 — Error presentation depth

- [ ] Add a `ScreenStateDefaultErrorView`/`ErrorUIView` variant that distinguishes a `URLError` (offline/timeout) from a generic error with a tailored icon and message, falling back to today's generic treatment for other error types.
- [ ] Add an optional secondary action slot (e.g. "Go Back" alongside "Retry") to the default Error placeholders, defaulting to hidden so existing call sites are unaffected.
- [ ] Add a `ScreenState.Error`-side helper to surface a user-facing message distinct from `localizedDescription` when the wrapped error conforms to a new `ScreenStateDisplayableError` protocol.
- [ ] Add snapshot tests for the new offline/timeout error variant across both SwiftUI and UIKit, at both standard and largest Dynamic Type sizes.
- [ ] Add a DocC "Error Presentation" article documenting the offline-aware variant, the secondary action slot, and `ScreenStateDisplayableError`.

## Week 14 — Performance & footprint

- [ ] Add a CI job that tracks `ScreenStates`' compiled binary size per release, failing if it regresses past a threshold, to keep the "dependency-free, lightweight" promise measurable rather than assumed.
- [ ] Audit `ScreenStateStore`'s `Task` lifecycle for an avoidable retain cycle between the stored in-flight `Task` and `self`, adding a regression test if one is found.
- [ ] Add a benchmark test (via `XCTest`'s `measure`) for `ScreenState.map`/`flatMap` under a large collection payload, to catch an accidental O(n²) regression in future changes.
- [ ] Audit the default placeholder views for unnecessary SwiftUI body re-evaluations on unrelated `ScreenStateStore` property changes (e.g. `isRefreshing` toggling shouldn't re-render an unrelated Error placeholder).
- [ ] Add a DocC "Performance" article documenting the binary-size budget, the `Task` lifecycle guarantee, and the re-render characteristics of the default placeholders.
