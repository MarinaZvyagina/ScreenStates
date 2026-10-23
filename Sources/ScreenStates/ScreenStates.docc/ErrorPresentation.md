# Error Presentation

Everything the default Error placeholders do beyond showing a generic icon and message: telling a connectivity problem apart from everything else, an optional second action alongside Retry, and a user-facing message distinct from `localizedDescription`.

## Overview

`.error` is the one state whose presentation can't be fully generic — a timed-out request, a missing article, and a malformed response all deserve different words, and sometimes a different action, even though they're all just an `Error` to ``ScreenStateStore``. This article rounds up the three pieces ``ScreenStateDefaultErrorView``/``ScreenStateDefaultErrorUIView`` use to narrow that gap without you writing a fully custom placeholder.

## The offline-aware variant

``ScreenState/isConnectivityError(_:)`` is `true` for a `URLError` indicating no network connectivity (`.notConnectedToInternet`, `.networkConnectionLost`) or a timed-out request (`.timedOut`). When it's `true`, the default Error placeholders swap their usual warning-triangle icon and "Something Went Wrong" title for a `wifi.exclamationmark` icon and "Connection Issue" instead — the same distinction a fully custom placeholder can make with the same check:

```swift
if ScreenState<Never>.isConnectivityError(error) {
    // show your own offline-specific treatment
}
```

Every other error, including other `URLError` codes, falls back to the generic treatment.

## The secondary action slot

Both default Error placeholders take an optional `secondaryAction: (title: String, action: () -> Void)?` alongside `onRetry` — a second button for something other than retrying, like going back to the previous screen instead of hammering a request that's going to fail the same way again:

```swift
ScreenStateDefaultErrorView(error: error, onRetry: reload, secondaryAction: (title: "Go Back", action: goBack))
ScreenStateDefaultErrorUIView(error: error, onRetry: reload, secondaryAction: (title: "Go Back", action: goBack))
```

It's `nil` by default, so every existing call site keeps showing just Retry (or nothing, if `onRetry` is also `nil`) until you opt in.

## A user-facing message, distinct from localizedDescription

`error.localizedDescription` is often a debugging string, or — for a plain `Error` with no `CustomStringConvertible`/`LocalizedError` conformance — just the type name, not something to put in front of the person using the app. Conform your own error type to ``ScreenStateDisplayableError`` to supply a message meant to actually be read:

```swift
struct APIError: ScreenStateDisplayableError {
    let displayMessage: String
}

store.setError(APIError(displayMessage: "That article was removed."))
```

``ScreenState/displayMessage(for:)`` checks for that conformance and falls back to `localizedDescription` for every other error. The default Error placeholders call it instead of `error.localizedDescription` directly, so adopting ``ScreenStateDisplayableError`` is enough to change what they show — no call-site changes needed.

## See Also

- ``ScreenState``
- ``ScreenStateDisplayableError``
- ``ScreenStateDefaultErrorView``
- ``ScreenStateDefaultErrorUIView``
- <doc:Accessibility>
