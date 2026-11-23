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
- [x] Tune the default placeholders for visionOS (ornaments/depth), which currently just inherit the iOS layout as-is.
- [x] Add a CI job that builds against the latest Xcode beta with `continue-on-error`, to catch upcoming toolchain breakage before it ships.
- [x] Fix the default placeholders' inset handling inside a `NavigationSplitView` detail column so they don't visually collide with the sidebar divider on iPad. (Verified, 2026-11-17: no defect found. Built a real `NavigationSplitView` into a universal (iPhone+iPad) build of the Demo app and screenshotted it via `xcrun simctl io screenshot` at genuine iPad width — 1032×1319pt, confirmed via an on-screen `GeometryReader` readout, after discovering the Demo app's `TARGETED_DEVICE_FAMILY: "1"` makes it run iPhone-compat-sized by default on iPad, which a naive test would have mistaken for a collision. At real width, the Error placeholder's existing `.padding(.horizontal, 24)` + centered `.frame` already sits with generous clearance from the sidebar divider. No code change needed.)

## Week 8 — Visual variety & theming

- [x] Add a "compact" style variant of the default placeholders (smaller icon/text) for embedding in a card or section rather than a whole screen.
- [x] Add a skeleton/shimmer-style Loading placeholder as an alternative opt-in built-in style.
- [x] Add an environment-based configuration point (tint/typography) so an app can theme the built-in placeholders globally instead of passing custom views at every call site.
- [x] Add a `redacted(reason: .placeholder)`-based Loading content option as an alternative to the spinner, mirroring the shape of the real content.
- [x] Add a DocC "Styling" article documenting the built-in style variants and the theming configuration point.

## Week 9 — Testing & tooling maturity

- [x] Add a CI matrix running the test suite against the last two Xcode versions, to catch regressions before a new major Xcode ships.
- [x] Add a `swift-format` (or SwiftLint) config plus a CI lint step, to keep style consistent across contributions.
- [x] Add a regression test asserting `ScreenStateStore.setData(_:)` with an unchanged, `Equatable` payload doesn't trigger a redundant `@Observable` invalidation.
- [x] Add an XCUITest that drives the Demo app through all four states end-to-end, catching integration regressions the unit suite can't.
- [x] Add tests locking in `ScreenState.map`/`flatMap`'s composition laws (identity, associativity) so future changes can't quietly break their semantics.

## Week 10 — Ecosystem & community growth

- [x] Add `CODE_OF_CONDUCT.md`.
- [x] Add `SECURITY.md` with a responsible-disclosure contact.
- [x] Add a GitHub Discussions Q&A category/template, linked from README, as a lighter-weight alternative to opening an issue.
- [x] Add a "Used By" section to README inviting adopters to add themselves via PR.
- [x] Add `.github/RELEASING.md` documenting the tag/publish process, matching the version-bump convention already used in `CHANGELOG.md`.

## Week 11 — Store ergonomics & analytics completeness

- [x] Add a `ScreenStateStore.refreshError`-clearing path so a successful `refresh(_:)` after a failed one doesn't leave the stale error dangling once `isRefreshing` flips back to `false`.
- [x] Add a `ScreenAnalyticsEvent` for retry taps specifically (distinct from a generic load event), so analytics can distinguish "user hit retry" from the initial load.
- [x] Add `ScreenStateStore.loadCollection(_:)`/`refreshCollection(_:)` analytics events mirroring the ones already tracked for `load(_:)`/`refresh(_:)`.
- [x] Add a `ScreenOpenSource`-aware convenience initializer on `ScreenStateStore` so call sites that already know their open source don't need a separate `track(openSource:)` call. (Decided against, 2026-11-03: would give the core, analytics-agnostic `ScreenStateStore` a direct dependency on `ScreenAnalyticsService` and a side effect in `init`, conflicting with `CONTRIBUTING.md`'s own API bar — "does every screen need this," not "could a screen use this" — and duplicating the already-established `observeStateChanges(of:screen:)` onboarding path. User decision: skip entirely, no code added.)
- [ ] Add a DocC code snippet (via `@Snippet`) for the retry-with-backoff recipe, replacing the current prose-only `loadWithRetry` example in the Recipes article.

## Week 12 — SwiftUI & UIKit parity

- [x] Audit `ScreenStateView`/`ScreenStateContainerView` for a parity gap: add whichever of `.screenState(_:onRetry:content:)`'s SwiftUI conveniences (e.g. a no-retry overload) is still missing from the UIKit `ScreenStateViewController` side. (Audited 2026-10-21: no gap found — `ScreenStateViewController` already has a matching default-placeholder init with `onRetry` defaulting to `nil`, already exercised by an existing test; `.screenState(_:)`'s modifier-chain sugar has no UIKit equivalent to begin with, since UIKit has no modifier-chain paradigm.)
- [x] Add a `ScreenStateView` initializer overload that takes an `EquatableValue` fast-path check (mirroring the `Equatable`-payload redundant-invalidation guard planned for `ScreenStateStore` in Week 9) to skip re-rendering identical `.data` content.
- [x] Add a UIKit `ScreenStateContainerView` snapshot test suite covering programmatic `bind(to:)` rebinding to a different store mid-lifecycle, which only has SwiftUI coverage today.
- [x] Expose `ScreenStateStore`'s `isRefreshing`/`refreshError` to UIKit consumers via a small delegate callback, mirroring how SwiftUI observes them through `@Observable`.
- [x] Add a DocC article cross-referencing equivalent SwiftUI/UIKit API pairs in a single table, so a reader working in one framework can find the other's equivalent at a glance.

## Week 13 — Error presentation depth

- [x] Add a `ScreenStateDefaultErrorView`/`ErrorUIView` variant that distinguishes a `URLError` (offline/timeout) from a generic error with a tailored icon and message, falling back to today's generic treatment for other error types.
- [x] Add an optional secondary action slot (e.g. "Go Back" alongside "Retry") to the default Error placeholders, defaulting to hidden so existing call sites are unaffected.
- [x] Add a `ScreenState.Error`-side helper to surface a user-facing message distinct from `localizedDescription` when the wrapped error conforms to a new `ScreenStateDisplayableError` protocol.
- [x] Add snapshot tests for the new offline/timeout error variant across both SwiftUI and UIKit, at both standard and largest Dynamic Type sizes.
- [x] Add a DocC "Error Presentation" article documenting the offline-aware variant, the secondary action slot, and `ScreenStateDisplayableError`.

## Week 14 — Performance & footprint

- [x] Add a CI job that tracks `ScreenStates`' compiled binary size per release, failing if it regresses past a threshold, to keep the "dependency-free, lightweight" promise measurable rather than assumed.
- [x] Audit `ScreenStateStore`'s `Task` lifecycle for an avoidable retain cycle between the stored in-flight `Task` and `self`, adding a regression test if one is found.
- [x] Add a benchmark test (via `XCTest`'s `measure`) for `ScreenState.map`/`flatMap` under a large collection payload, to catch an accidental O(n²) regression in future changes.
- [x] Audit the default placeholder views for unnecessary SwiftUI body re-evaluations on unrelated `ScreenStateStore` property changes (e.g. `isRefreshing` toggling shouldn't re-render an unrelated Error placeholder).
- [x] Add a DocC "Performance" article documenting the binary-size budget, the `Task` lifecycle guarantee, and the re-render characteristics of the default placeholders.

## Week 15 — Pagination ergonomics

- [x] Add `ScreenStateStore.loadNextPage(_:)` for `Value: RangeReplaceableCollection`, appending a new page to existing `.data` instead of replacing it, with its own `isLoadingNextPage` flag.
- [x] Add `loadNextPageError`, mirroring `refreshError`, so a failed page fetch doesn't discard already-loaded pages.
- [x] Guard `loadNextPage(_:)` against the same overlapping/stale-result race already guarded for `load`/`refresh`, with a regression test.
- [x] Add a `ScreenAnalyticsEvent` for pagination (`screen_next_page_loaded`/`screen_next_page_failed`), mirroring the existing retry/load-duration events.
- [x] Add a DocC "Pagination" article documenting `loadNextPage(_:)`, `isLoadingNextPage`, and `loadNextPageError`, with a List-plus-"Load More" example.

## Week 16 — Internationalization reach

- [x] Add Spanish and French localizations to `Localizable.xcstrings` (currently English + Russian only).
- [x] Add RTL snapshot tests (Arabic locale) for the default Empty/Error placeholders, verifying icon/text ordering flips correctly.
- [x] Audit the default placeholders' Dynamic Type + RTL combination at the largest accessibility size, fixing any clipping/mirroring issue found.
- [x] Add a DocC "Localization" article documenting how to add a language to `Localizable.xcstrings` and override individual default strings per-app.
- [x] Add a CI check that fails if `Localizable.xcstrings` has a string present in English but missing a translation in any other configured language.

## Week 17 — Developer experience & CI maturity

- [x] Add a CI job running `swift package diagnose-api-breaking-changes` against the latest git tag, to catch an accidental breaking change before merge.
- [x] Add a CI job building the package for visionOS (`continue-on-error` initially) — GitHub's hosted runners carry the visionOS SDK even though local dev doesn't, unblocking visionOS verification without a local SDK install.
- [x] Automate `Scripts/generate-docs.sh` into a CI job that regenerates and commits `docs/` on every push to `main`, mirroring the self-committing coverage-badge job, instead of a manual step.
- [x] Add a CI job enforcing a minimum code-coverage floor (a failing gate, not just the existing informational badge), mirroring the binary-size-budget's "bump the committed threshold for an intentional change" pattern.
- [x] Audit every public type for an explicit `Sendable` annotation where Swift 6's inferred conformance is non-obvious, adding one where missing.

## Week 18 — Demo app depth & polish

- [x] Add a paginated list screen to the Demo app exercising `loadNextPage(_:)` (Week 15's feature) end-to-end.
- [x] Add a Demo app screen exercising a custom `ScreenStateDisplayableError`-conforming error type, as a runnable example of the Error Presentation article's recipe.
- [x] Add an XCUITest covering the secondary-action button (already shipped) end-to-end in the Demo app.
- [x] Add a CONTRIBUTING.md section on how to add a new default-placeholder style variant, as a short internal-contributor guide.
- [x] Add a FAQ section to README answering the most likely setup questions (platform minimums, UIKit vs SwiftUI choice, when to reach for analytics).

## Week 19 — Store & state Swift-idiom polish

- [x] Add `Hashable` conformance to `ScreenState` when `Value: Hashable`, mirroring the existing conditional `Equatable` conformance, so it can be used as a `Set`/`Dictionary` key.
- [x] Add `CustomDebugStringConvertible` to `ScreenState`, giving `po state`/print output a concise one-line description instead of the verbose default enum dump.
- [x] Audit `ScreenStateStore.setData(_:)`'s `Value: Equatable` redundant-invalidation guard against a reference-type (class) `Value`, confirming it behaves correctly when `==` isn't identity-based, with a regression test.
- [x] Audit whether `cancel()` is safely idempotent when called repeatedly with nothing in flight, and when called twice in a row mid-flight; add a regression test locking in the current behavior.
- [x] Add `isData`/`isError` boolean convenience properties to `ScreenState`, completing the `isEmpty`/`isLoading` family (today only `value != nil`/`error != nil` serve as workarounds).

## Week 20 — UIKit pull-to-refresh parity

- [x] Add a `pullToRefresh: (() async -> Void)?` parameter to `ScreenStateContainerView`'s built-in-placeholders initializer, wiring a `UIRefreshControl` that calls it and ends spinning when it completes.
- [x] Thread `pullToRefresh` through `ScreenStateViewController`'s matching built-in-placeholders initializer.
- [x] Sync the `UIRefreshControl`'s spinning state with the bound store's `isRefreshing` even when refresh is triggered programmatically elsewhere, so the control can't get stuck. (Shipped as part of the previous item's commit — `observeIsRefreshing(_:generation:)`'s existing observation bridge already needed to drive this, since it's the only mechanism that can detect `isRefreshing` changing for *any* reason, not just the pull gesture. No separate commit, since there was no additional code left to write.)
- [x] Add a Demo app screen (or extend an existing one) exercising UIKit pull-to-refresh end-to-end.
- [x] Add a "Getting Started with UIKit" DocC update + README API table row documenting `pullToRefresh` as UIKit's equivalent of SwiftUI's `.refreshable { }`.

## Week 21 — UIKit theming parity

- [ ] Add a `UITraitDefinition` for `ScreenStatesTheme` (tint/titleFont/messageFont), bridging to/from SwiftUI's environment-based theme via `UITraitBridgedEnvironmentKey`.
- [ ] Wire the default UIKit placeholder views to read this trait and apply it the same way the SwiftUI views already do.
- [ ] Confirm (and document) that `traitOverrides` on `ScreenStateContainerView`/`ScreenStateViewController` propagates the theme correctly through a mixed SwiftUI-in-UIKit or UIKit-in-SwiftUI hierarchy.
- [ ] Add regression tests covering the trait-based theme override, both directly and through a mixed hierarchy.
- [ ] Add a "Styling" DocC article update covering the UIKit trait-based theming path alongside the existing SwiftUI environment-based one.

## Week 22 — Testing & tooling maturity round 2

- [ ] Add a CI job running the test suite with Thread Sanitizer enabled, to catch a data race the Swift 6 compiler's static checks might miss around a `nonisolated(unsafe)` property.
- [ ] Add a lightweight CI check that fails if `Package.swift` gains a `dependencies:` entry without the same PR updating README's "dependency-free" framing.
- [ ] Add a CI check (grep-based) that fails if a new `public` declaration is added without a corresponding row in README's API reference table — catching the kind of gap the `secondaryAction` convenience-init miss slipped through.
- [ ] Add a "regression report" issue template distinct from the general bug template, prompting for the last-known-good version — easier to correlate against a tag now that releases are being cut again.
- [ ] Add a CI job that diffs the public API surface and posts a human-readable ADDED/REMOVED/CHANGED summary as a PR comment, making review faster without needing the full breaking-changes tool.

## Week 23 — Accessibility depth round 2

- [ ] Audit default placeholder titles for an appropriate `accessibilityHeading` trait where relevant, fixing any gap found.
- [ ] Add a regression test confirming `accessibilityIdentifier` values never leak into VoiceOver's spoken label (should already be separate, but unverified explicitly).
- [ ] Audit the default placeholders against Reduce Transparency (`accessibilityReduceTransparency`) — the visionOS glass-depth material is explicitly a transparency effect; add a solid-background fallback when Reduce Transparency is on, mirroring the existing Reduce Motion/Increase Contrast pattern.
- [ ] Add a CI job enforcing a minimum WCAG "AA" contrast ratio on the default placeholders' text/icon colors against their backgrounds, even when Increase Contrast is off.
- [ ] Add an "Accessibility" DocC article update covering Reduce Transparency and the new contrast-ratio guarantee.

## Week 24 — Localization reach round 2

- [ ] Add German and Japanese localizations to `Localizable.xcstrings` (currently English/Russian/Spanish/French).
- [ ] Add Simplified Chinese and Arabic localizations (Arabic already has RTL layout tests but no actual translated strings yet).
- [ ] Audit whether any current string would benefit from `.xcstrings` plural variation; add one if justified, or document why none is needed.
- [ ] Extend the existing Dynamic Type snapshot tests with a locale axis, confirming the longest-translated string (often German) doesn't clip.
- [ ] Add a "Localization" DocC article update documenting the two new languages and the longest-string Dynamic Type guarantee.

## Week 25 — Demo app depth round 2

- [ ] Add a Demo app screen demonstrating UIKit pull-to-refresh (Week 20) end-to-end.
- [ ] Add a Demo app screen demonstrating the UIKit theming trait (Week 21).
- [ ] Add a settings-style Demo app screen letting a person toggle between all six supported languages at runtime.
- [ ] Add a Demo app screen demonstrating `isData`/`isError` (Week 19) in a realistic conditional-UI spot.
- [ ] Re-record the Demo app GIF/README screenshot now that the app has grown past what's currently shown.

## Week 26 — Error presentation depth round 2

- [ ] Add a `ScreenStateDisplayableError` example with a localized `displayMessage` (today's example is a single hardcoded English string), documented in the Error Presentation article.
- [ ] Add `ScreenState.isServerError(_:)`, recognizing a 5xx-style server error distinct from a connectivity error, with its own icon/title treatment.
- [ ] Thread the new server-error treatment through both SwiftUI and UIKit default Error placeholders, matching the connectivity-error pattern.
- [ ] Add regression + snapshot tests for the new server-error treatment across both placeholder flavors.
- [ ] Add an "Error Presentation" DocC article update covering the new category.

## Week 27 — Performance & footprint round 2

- [ ] Add a CI job tracking the DocC archive's output size against a budget, alongside the existing compiled-binary-size budget.
- [ ] Add a deterministic (not wall-clock) benchmark test for `ScreenAnalyticsService.track(_:)`'s fan-out loop with many registered trackers.
- [ ] Add a deterministic regression test confirming `loadNextPage(_:)`'s page-append isn't accidentally O(n²) for a large existing collection.
- [ ] Add a CI job tracking `swift build` wall-clock time against a budget, to catch an accidental compile-time regression.
- [ ] Add a "Performance" DocC article update covering the new doc-archive-size and build-time budgets.

## Week 28 — Release-cadence tooling

- [ ] Add a script + CI job (non-blocking initially) warning if more than 15 un-tagged `CHANGELOG.md` entries have accumulated since the last git tag — directly motivated by the 91-version gap between `v1.4.0` and `v1.95.0` going unnoticed for months.
- [ ] Add a CI check verifying the newest git tag's annotated message includes a `Highlights:` section and an explicit breaking-change statement.
- [ ] Add a "when to tag" cadence guideline to `RELEASING.md`, informed by the previous item's threshold.
- [ ] Audit README's SPM installation instructions for exact-version vs. up-to-next-major guidance, filling any gap found.
- [ ] Cross-reference `RELEASING.md`'s new cadence guideline from `CONTRIBUTING.md`.

## Week 29 — Community & docs round 2

- [ ] Add a "Project Status" section to README linking to `ROADMAP.md`, which currently isn't linked from anywhere.
- [ ] Add a visual distinction in `CHANGELOG.md` between tagged and untagged versions.
- [ ] Add a GitHub issue template for "add a language," prompting for the language code and a translation-review commitment.
- [ ] Add an "Adopting ScreenStates incrementally" article covering how to introduce it screen-by-screen alongside an existing pattern, without a big-bang rewrite.
- [ ] Add `contact_links` entries to `.github/ISSUE_TEMPLATE/config.yml` for Q&A Discussions and SECURITY.md's contact — today neither is surfaced in GitHub's issue-creation picker, only in README prose.

## Week 30 — Platform & environment polish round 2

- [ ] Audit the default placeholders under Mac Catalyst's "Optimized for Mac" (non-scaled) idiom mode specifically, confirming Week 7's sizing still applies or needs adjustment.
- [ ] Audit the default placeholders in a narrow Stage-Manager-windowed iPad layout — a narrow floating window isn't always short, so `verticalSizeClass` compact-height alone doesn't cover it.
- [ ] Add `horizontalSizeClass == .compact` layout tuning for the default Empty/Error placeholders (today only vertical compact-height is handled) — relevant for Slide Over, a narrow Stage Manager window, or Split View.
- [ ] Add regression snapshot tests for the new horizontal-compact layout, mirroring the existing compact-height test structure.
- [ ] Extend README/DocC's "compact-height (landscape iPhone)" paragraph to also cover compact-width scenarios.
