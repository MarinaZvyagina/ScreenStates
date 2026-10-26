# Performance

The binary-size budget, the `Task` lifecycle guarantee, and the re-render characteristics of the default placeholders — what's measured, what's guaranteed, and why.

## Overview

ScreenStates' pitch is "small, dependency-free, drop into any screen." This article covers the three ways that's kept measurable rather than just assumed: a CI-enforced size budget, an audited concurrency guarantee, and a documented rendering characteristic.

## The binary-size budget

CI builds `swift build -c release` on every push and sums the resulting `.o` sizes for the `ScreenStates` target, failing the build if that total exceeds the budget committed in `.github/binary-size-budget.json`. There's no single linked artifact to measure instead — the library product is "automatic," and nothing in the package's own build graph links it standalone — so the `.o` total is the closest deterministic proxy available.

A legitimate feature addition that grows this total past the budget isn't blocked forever: bump `maxBytes` in that file as part of the same PR, the same way a dependency lockfile gets updated alongside the change that needed it. The job never bumps it on its own.

## The Task lifecycle guarantee

``ScreenStateStore``'s `load`/`loadCollection`/`refresh`/`refreshCollection`/`loadWithRetry` each store their running `Task` in a private `currentTask` property, read by ``ScreenStateStore/cancel()`` and `deinit`. Every one of those `Task`s captures `self` as `[weak self]`, not strongly — audited specifically to rule out a `self -> currentTask -> closure -> self` retain cycle keeping a store alive after its last external reference is dropped.

In practice, a completed `Task` releases its closure's captures on return regardless of capture style, so this mostly matters for a still-*running* operation: without `[weak self]`, a store couldn't become eligible for deallocation until that operation finished, even once every other reference to it was already gone. See <doc:ConcurrencyAndCancellation> for the rest of the `Task` lifecycle — cancellation, overlapping calls, and the automatic cancel-on-`deinit` safety net this guarantee supports.

## Re-render characteristics of the default placeholders

``ScreenStateStore/isRefreshing`` and ``ScreenStateStore/refreshError`` only ever go active once ``ScreenStateStore/refresh(_:)``/``ScreenStateStore/refreshCollection(_:)`` have confirmed `state` is already `.data` — both fall back to `load(_:)`/`loadCollection(_:)` otherwise, which never touch either property. That means `isRefreshing`/`refreshError` can never be observed alongside `.empty`, `.loading`, or `.error`, so none of the three default placeholders can ever be on screen mid-refresh.

A parent view that reads `store.state` (via ``ScreenStateView``) and `store.isRefreshing`/`refreshError` in the same `body` — the pattern <doc:GettingStartedWithSwiftUI> uses for a refresh toast — still has its `body` re-evaluated whenever either changes, same as any `@Observable` property read in a SwiftUI `body`. This guarantee is about *which* placeholder that re-evaluation could ever affect, not about avoiding the re-evaluation itself: since a default placeholder is only ever on screen while `isRefreshing`/`refreshError` are both inactive, that re-evaluation never has a placeholder to needlessly re-render in the first place — only whatever renders the `.data` case could be affected.

## See Also

- ``ScreenStateStore``
- <doc:ConcurrencyAndCancellation>
- <doc:GettingStartedWithSwiftUI>
