# Changelog

All notable changes to this project are documented in this file.
Versioning follows [Semantic Versioning](https://semver.org/) (`major.minor.patch`).

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
