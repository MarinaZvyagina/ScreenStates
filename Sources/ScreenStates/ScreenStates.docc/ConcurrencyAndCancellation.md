# Concurrency & Cancellation

The guarantees ``ScreenStateStore`` makes about overlapping, cancelled, and reset calls.

## Overview

``ScreenStateStore`` is `@MainActor` and built under Swift 6 strict concurrency. Every `load`/`loadCollection`/`refresh`/`refreshCollection`/`loadWithRetry` call is `async`, which raises three questions the moment a screen does more than one of them: what happens if a second call starts before the first finishes? How do you stop one early? And how do you force a store back to a known state outside of any of them? This article covers all three.

## Overlapping calls only ever apply the latest result

Nothing extra is needed to handle a screen firing off a second call before an earlier one has finished — a fast double-tap on Retry, or a new search query arriving before the previous one resolved:

```swift
await store.load { try await api.fetchArticle(id: 1) } // slow — still in flight
await store.load { try await api.fetchArticle(id: 2) } // fast — resolves first
```

Internally, every call stamps itself with a token before running `operation`, and only applies its result — `.data`, `.error`, or the `.empty` mapping `loadCollection(_:)`/`refreshCollection(_:)` do — if that token is still the most recently started one by the time `operation` resolves. In the example above, article 1's slower fetch resolving *after* article 2's result is already showing never overwrites it; its result is silently dropped. `refresh(_:)`/`refreshCollection(_:)`'s `isRefreshing` follows the same rule: it only clears once the *newest* in-flight refresh finishes, not whichever overlapping one happens to resolve first.

You don't need to call ``ScreenStateStore/cancel()`` for this to hold — it's automatic. Reach for `cancel()` when you additionally want to stop the older call's work from running at all, not just prevent its result from landing.

## Cancelling explicitly

Call ``ScreenStateStore/cancel()`` to stop whatever call is currently running, without waiting for it to resolve:

```swift
store.cancel() // e.g. from onDisappear, or right before firing off a newer query
```

`state` (and `isRefreshing`/`refreshError`) are left exactly as they were — cancelling never surfaces a `CancellationError` through `state` the way letting `operation` itself fail would. This applies uniformly, including to ``ScreenStateStore/loadWithRetry(maxAttempts:backoff:_:)`` cancelled mid-backoff: it stops retrying and leaves `state` untouched, just like every other call. If nothing is in flight, `cancel()` does nothing.

## Cancelling automatically

A store also cancels whatever it was still tracking when it's deallocated, as a last-resort safety net — you don't need to call `cancel()` from `deinit` yourself. In practice this rarely has anything to do: `load`/`refresh`/etc. already `await` their own work to completion before returning, so by the time a store can actually be deallocated, there's normally nothing left in flight to cancel. It exists to guard against that assumption changing later, for free.

## Resetting outside of a load

``ScreenStateStore/reset(to:)`` snaps a store back to `.loading` (or any state you give it) without going through `load`/`refresh` at all — useful for a full sign-out flow, where whatever the store was showing or fetching no longer applies to the next signed-in user:

```swift
func signOut() {
    session.clear()
    articlesStore.reset() // back to .loading, as if freshly created
}
```

Like `cancel()`, it stops whatever operation is currently in flight; unlike `cancel()`, it also immediately replaces `state` and clears `isRefreshing`/`refreshError`, so a screen bound to the store reflects the reset right away instead of waiting for a cancelled operation to unwind.

## See Also

- ``ScreenStateStore``
- <doc:GettingStartedWithSwiftUI>
