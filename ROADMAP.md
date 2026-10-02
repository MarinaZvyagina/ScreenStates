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
- [ ] Add `ScreenStateStore.reset(to:)` to snap a store back to `.loading` (or any given state) outside of a `load` call — useful for a full sign-out/reset flow.
- [ ] Add a DocC "Concurrency & Cancellation" article documenting the guarantees above.

## Week 6 — Accessibility depth

- [ ] Respect Reduce Motion for the default Loading spinner's animation (`accessibilityReduceMotion` in SwiftUI, `UIAccessibility.isReduceMotionEnabled` in UIKit).
- [ ] Respect Increase Contrast for the gradient Empty/Loading/Error icons, falling back to a solid high-contrast tint.
- [ ] Add Dynamic Type snapshot tests at the largest accessibility text sizes for all six default placeholders.
- [ ] Expose a stable, reusable VoiceOver announcement string per `ScreenState` case (not just baked into the default placeholders), so fully custom placeholders can announce transitions with the same wording.
- [ ] Add a DocC "Accessibility" article rounding up VoiceOver, Reduce Motion, Increase Contrast, Dynamic Type, and identifiers in one place.

## Week 7 — Platform & environment polish

- [ ] Tune the default placeholders for Mac Catalyst (pointer/hover states, typography sized for a mouse-driven window rather than touch).
- [ ] Tune the default placeholders for landscape / compact-height iPhone layouts, which currently assume a portrait-sized column.
- [ ] Tune the default placeholders for visionOS (ornaments/depth), which currently just inherit the iOS layout as-is.
- [ ] Add a CI job that builds against the latest Xcode beta with `continue-on-error`, to catch upcoming toolchain breakage before it ships.
- [ ] Fix the default placeholders' inset handling inside a `NavigationSplitView` detail column so they don't visually collide with the sidebar divider on iPad.

## Week 8 — Visual variety & theming

- [ ] Add a "compact" style variant of the default placeholders (smaller icon/text) for embedding in a card or section rather than a whole screen.
- [ ] Add a skeleton/shimmer-style Loading placeholder as an alternative opt-in built-in style.
- [ ] Add an environment-based configuration point (tint/typography) so an app can theme the built-in placeholders globally instead of passing custom views at every call site.
- [ ] Add a `redacted(reason: .placeholder)`-based Loading content option as an alternative to the spinner, mirroring the shape of the real content.
- [ ] Add a DocC "Styling" article documenting the built-in style variants and the theming configuration point.

## Week 9 — Testing & tooling maturity

- [ ] Add a CI matrix running the test suite against the last two Xcode versions, to catch regressions before a new major Xcode ships.
- [ ] Add a `swift-format` (or SwiftLint) config plus a CI lint step, to keep style consistent across contributions.
- [ ] Add a regression test asserting `ScreenStateStore.setData(_:)` with an unchanged, `Equatable` payload doesn't trigger a redundant `@Observable` invalidation.
- [ ] Add an XCUITest that drives the Demo app through all four states end-to-end, catching integration regressions the unit suite can't.
- [ ] Add tests locking in `ScreenState.map`/`flatMap`'s composition laws (identity, associativity) so future changes can't quietly break their semantics.

## Week 10 — Ecosystem & community growth

- [ ] Add `CODE_OF_CONDUCT.md`.
- [ ] Add `SECURITY.md` with a responsible-disclosure contact.
- [ ] Add a GitHub Discussions Q&A category/template, linked from README, as a lighter-weight alternative to opening an issue.
- [ ] Add a "Used By" section to README inviting adopters to add themselves via PR.
- [ ] Add `.github/RELEASING.md` documenting the tag/publish process, matching the version-bump convention already used in `CHANGELOG.md`.
