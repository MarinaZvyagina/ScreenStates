# Contributing to ScreenStates

Thanks for considering a contribution. ScreenStates is a small, dependency-free package, and it's meant to stay that way — the bar for new API is "does every screen need this," not "could a screen use this." Everyone participating is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Build & test

`Package.swift` targets iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, and visionOS 1+. `swift build`/`swift test` work directly on macOS and are a fast local sanity check, but macOS has neither UIKit-the-full-framework nor SwiftUI's full surface, so they won't catch everything.

The authoritative check — and what CI runs — is `xcodebuild` against an iOS Simulator:

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | test("iPhone"))][0].udid')
xcodebuild test -scheme ScreenStates -destination "platform=iOS Simulator,id=$UDID"
```

Run this before opening a PR. If your change touches a `#if canImport(UIKit)`/`#if canImport(SwiftUI)` guard, run `swift build`/`swift test` too — that's usually where a missing guard shows up first.

CI also runs the same suite against the last two GA Xcode versions installed on the runner image (a real, blocking check — a regression on an older still-supported Xcode is as real as one on the newest), and separately against whatever Xcode beta happens to be newest on the runner, as a non-blocking canary for upcoming toolchain breakage (`continue-on-error`, so a red run there is worth a look but never blocks a PR).

The tvOS/watchOS/visionOS SDKs aren't required for local development; every UIKit-only file is guarded with `#if canImport(UIKit) && !os(watchOS)`, so a code review plus the two builds above is enough to verify platform correctness without installing every additional simulator runtime. CI additionally builds the package for visionOS (`continue-on-error`, since that job is still new) on GitHub's hosted runners, which carry the SDK even though local dev doesn't — the only place visionOS-specific code actually gets compiled today.

CI also builds `swift build -c release` and sums the resulting `.o` sizes against a budget committed in `.github/binary-size-budget.json`, to keep the "dependency-free, lightweight" promise measurable rather than assumed. If your change legitimately grows that total past the budget, bump `maxBytes` there as part of the same PR — the job never bumps it on its own.

Line coverage is also checked against a floor committed in `.github/coverage-floor.json` — a blocking check, unlike the informational coverage badge in the README. If your change legitimately drops coverage below that floor (e.g. removing a heavily-tested code path), bump `minPercent` there as part of the same PR.

If you add or change a string in `Resources/Localizable.xcstrings`, make sure every language already in the catalog has a translated entry for it — CI fails the build otherwise (see [`Localization`](https://marinazvyagina.github.io/ScreenStates/documentation/screenstates/localization) for how to add a language or a string).

## Style

CI runs `swift format lint` (bundled with the Swift 6 toolchain — nothing extra to install) against `.swift-format`'s project config, as a blocking check. Run it yourself before opening a PR:

```bash
swift format lint --configuration .swift-format --recursive --strict Sources Tests
```

`swift format format --configuration .swift-format -i --recursive Sources Tests` auto-fixes most findings. A couple of spots wrap a single `.modifier()` mid-chain in `#if`/`#endif` (not a whole statement) — the formatter misindents those, so they're marked `// swift-format-ignore` and keep their hand-written indentation; leave that comment in place if you touch one.

## Adding a new default-placeholder style variant

There are two different things "a new placeholder style" can mean in this codebase — pick the one that matches what you're actually adding:

- **A new case of `ScreenStatePlaceholderStyle`** (`Sources/ScreenStates/Core/ScreenStatePlaceholderStyle.swift`), like the existing `.standard`/`.compact`: a layout variation of the *same* default view, selected via its `style:` parameter. Every default placeholder (`ScreenStateDefault{Empty,Loading,Error}View`/`UIView`) switches on it — e.g. `SwiftUIDefaultStateViews.swift`'s `iconSize(for:)`/`spinnerSize(for:)` — so adding a case means updating every one of those switches, not just the one view you care about. This is the right shape when the variant is a sizing/layout tweak that should be available on every default placeholder uniformly.
- **A standalone opt-in alternative view**, like `ScreenStateShimmerLoadingView`/`ScreenStateShimmerLoadingUIView`: a full drop-in replacement for one placeholder slot (Empty, Loading, or Error), not wired into the `.standard`/`.compact` switch at all. This is the right shape when the variant is a different visual idea entirely (a skeleton pulse instead of a spinner, say), not a resize of the existing one. Build it as a SwiftUI/UIKit pair living in `Sources/ScreenStates/SwiftUI/` and `Sources/ScreenStates/UIKit/` respectively, and give it the same accessibility treatment every other default placeholder has: an `accessibilityLabel`/`accessibilityIdentifier` (follow the `screenStates.<name>` naming already in use), a Reduce Motion check before animating, an Increase Contrast fallback away from any gradient/low-opacity fill, and `.screenStatesTheme(_:)`/`ScreenStatesTheme` support if it renders a tint color. Since it's opt-in, it's passed explicitly wherever a `loadingView`/`emptyView`/`errorView`-shaped parameter is expected — it never becomes a default itself.

Either way, this is a feature-level change: it needs `PlaceholderVisualTests.swift` snapshot coverage (reuse the existing `snapshotImage`/`containsSaturatedColor` helpers), a README update (the API reference table, plus the relevant usage section), a `CHANGELOG.md` entry, and a mention in the Styling DocC article.

## Making a change

- Keep commits small and scoped to one change. Follow the existing `feat:`/`fix:`/`docs:`/`ci:`/`test:` prefix style — see `git log` for examples.
- A feature-level change (new public API, new behavior) should update, in the same PR: the source file(s), tests under `Tests/ScreenStatesTests/`, the relevant `README.md` usage section and API reference table, a `CHANGELOG.md` entry (bump the minor version), and — for new public API — the DocC catalog under `Sources/ScreenStates/ScreenStates.docc/`.
- A fix, refactor, or infra change doesn't need all of the above, but should still get a `CHANGELOG.md` entry if it's user-visible.
- Run the full test suite (see above) before pushing. Don't open a PR with a failing build.
- A `CHANGELOG.md` bump doesn't itself cut a release — see [`.github/RELEASING.md`](.github/RELEASING.md) for the (maintainer-only) tag/publish process.

## Reporting bugs and requesting features

Please use the issue templates — they ask for just enough context (platform, Swift/Xcode version, repro steps for bugs) to act on the report without a round trip. For a suspected security vulnerability, see [`SECURITY.md`](SECURITY.md) instead — please don't open a public issue for those.

If you're not sure something is a bug, or you're just stuck on how to use an API, [**Q&A Discussions**](https://github.com/MarinaZvyagina/ScreenStates/discussions/categories/q-a) is a lighter-weight alternative to opening an issue.

## Pull requests

Fill out the PR template. Small, focused PRs are easier to review than one PR covering several unrelated changes — if you're touching more than one of the areas above, consider splitting it up.
