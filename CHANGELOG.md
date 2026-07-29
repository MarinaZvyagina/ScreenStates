# Changelog

All notable changes to this project are documented in this file.
Versioning follows [Semantic Versioning](https://semver.org/) (`major.minor.patch`).

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
