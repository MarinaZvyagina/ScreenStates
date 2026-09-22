# Roadmap

A month of small, incremental improvements to ScreenStates, one item per day. See `CLAUDE.md` for how these get picked up and shipped.

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
- [ ] Add a CI check that builds the DocC catalog, so broken doc comments/links fail the build.

## Week 4 — Analytics depth & community health

- [ ] Track screen load duration (`.loading` → `.data`/`.error` elapsed time) as a new `ScreenAnalyticsEvent`.
- [ ] Add `loadWithRetry(maxAttempts:backoff:)` to `ScreenStateStore` for automatic retry with backoff.
- [ ] Add `CONTRIBUTING.md` plus issue/PR templates.
- [ ] Add a DocC "Recipes" article covering common patterns (list + detail, one store per tab, master-detail).
- [ ] Publish to the Swift Package Index (`.spi.yml`) and add an SPI badge to the README.
