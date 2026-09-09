# ScreenStates

A small, dependency-free Swift package: one `ScreenState<Value>` enum (Empty/Loading/Data/Error) plus SwiftUI and UIKit views that render it. See `README.md` for the full pitch and API.

## Build & test

This package only declares `.iOS(.v17)` in `Package.swift`, so plain `swift build`/`swift test` fail on macOS (they target the host macOS SDK by default, and the code uses iOS/Observation APIs unavailable there). Always test via `xcodebuild` against an iOS Simulator instead, picking whatever simulator is actually installed rather than hardcoding a device name:

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | test("iPhone"))][0].udid')
xcodebuild test -scheme ScreenStates -destination "platform=iOS Simulator,id=$UDID"
```

This is exactly what `.github/workflows/tests.yml` runs in CI.

## Commit conventions

- Every commit in this repo is authored solely by Marina Oreshina. Do **not** add a `Co-Authored-By: Claude` (or similar) trailer to commit messages in this repository — this was explicitly requested after it showed up in GitHub's Contributors list.
- Keep commits small and scoped to one change. Follow the existing style: `feat:`/`fix:`/`docs:`/`ci:`/`test:` prefixes (see `git log` for examples).
- Every feature-level change should, like existing history, update: the relevant source file(s), `Tests/ScreenStatesTests/`, `README.md` (usage + API reference table), `CHANGELOG.md` (bump the minor version, one entry per change), and — for new public API — the DocC catalog under `Sources/ScreenStates/ScreenStates.docc/`.
- Run the full test suite (see above) before committing. Never commit if it doesn't pass.

## The daily roadmap

`ROADMAP.md` at the repo root tracks a month of small, incremental improvements, one per day, being worked through automatically. When asked to "continue the roadmap" or similar:

1. Open `ROADMAP.md`, find the first unchecked (`- [ ]`) item.
2. Implement *only* that item, following the commit conventions above (small, tested, documented).
3. Check its box (`- [x]`) in `ROADMAP.md` as part of the same commit.
4. Commit, then push directly to `origin/main` — this has been explicitly pre-authorized for this recurring workflow (see `.claude/settings.json`), so no need to ask for confirmation before pushing.
5. Stop after one item — don't cascade into the next one in the same run.

If the next unchecked item turns out to be already done, ambiguous, or blocked by a decision only the user can make, skip the autonomous push, leave the item unchecked, and explain why instead of guessing.
