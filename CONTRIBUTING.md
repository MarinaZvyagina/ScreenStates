# Contributing to ScreenStates

Thanks for considering a contribution. ScreenStates is a small, dependency-free package, and it's meant to stay that way — the bar for new API is "does every screen need this," not "could a screen use this."

## Build & test

`Package.swift` targets iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, and visionOS 1+. `swift build`/`swift test` work directly on macOS and are a fast local sanity check, but macOS has neither UIKit-the-full-framework nor SwiftUI's full surface, so they won't catch everything.

The authoritative check — and what CI runs — is `xcodebuild` against an iOS Simulator:

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | test("iPhone"))][0].udid')
xcodebuild test -scheme ScreenStates -destination "platform=iOS Simulator,id=$UDID"
```

Run this before opening a PR. If your change touches a `#if canImport(UIKit)`/`#if canImport(SwiftUI)` guard, run `swift build`/`swift test` too — that's usually where a missing guard shows up first.

CI also runs the same suite against the last two GA Xcode versions installed on the runner image (a real, blocking check — a regression on an older still-supported Xcode is as real as one on the newest), and separately against whatever Xcode beta happens to be newest on the runner, as a non-blocking canary for upcoming toolchain breakage (`continue-on-error`, so a red run there is worth a look but never blocks a PR).

The tvOS/watchOS/visionOS SDKs aren't required for local development; every UIKit-only file is guarded with `#if canImport(UIKit) && !os(watchOS)`, so a code review plus the two builds above is enough to verify platform correctness without installing every additional simulator runtime.

## Style

CI runs `swift format lint` (bundled with the Swift 6 toolchain — nothing extra to install) against `.swift-format`'s project config, as a blocking check. Run it yourself before opening a PR:

```bash
swift format lint --configuration .swift-format --recursive --strict Sources Tests
```

`swift format format --configuration .swift-format -i --recursive Sources Tests` auto-fixes most findings. A couple of spots wrap a single `.modifier()` mid-chain in `#if`/`#endif` (not a whole statement) — the formatter misindents those, so they're marked `// swift-format-ignore` and keep their hand-written indentation; leave that comment in place if you touch one.

## Making a change

- Keep commits small and scoped to one change. Follow the existing `feat:`/`fix:`/`docs:`/`ci:`/`test:` prefix style — see `git log` for examples.
- A feature-level change (new public API, new behavior) should update, in the same PR: the source file(s), tests under `Tests/ScreenStatesTests/`, the relevant `README.md` usage section and API reference table, a `CHANGELOG.md` entry (bump the minor version), and — for new public API — the DocC catalog under `Sources/ScreenStates/ScreenStates.docc/`.
- A fix, refactor, or infra change doesn't need all of the above, but should still get a `CHANGELOG.md` entry if it's user-visible.
- Run the full test suite (see above) before pushing. Don't open a PR with a failing build.

## Reporting bugs and requesting features

Please use the issue templates — they ask for just enough context (platform, Swift/Xcode version, repro steps for bugs) to act on the report without a round trip.

## Pull requests

Fill out the PR template. Small, focused PRs are easier to review than one PR covering several unrelated changes — if you're touching more than one of the areas above, consider splitting it up.
