# Tracking Screen Analytics

Send screen-opened and state-transition events to any analytics backend with ``ScreenAnalyticsService``.

## Overview

Every screen that models its state with ``ScreenStateStore`` already knows exactly when it was opened and when it moves between Empty, Loading, Data, and Error. ``ScreenAnalyticsService`` turns those moments into ``ScreenAnalyticsEvent``s and fans them out to as many ``ScreenAnalyticsTracker``s as you register — one per analytics backend (Firebase, Mixpanel, Amplitude, your own logging endpoint, a debug console print, ...).

ScreenStates ships no concrete tracker implementations, so the core module stays dependency-free. You write one small adapter per backend, converting the event's backend-agnostic ``AnalyticsValue`` parameters into that SDK's own format:

```swift
struct FirebaseScreenTracker: ScreenAnalyticsTracker {
    func track(_ event: ScreenAnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters.mapValues { value in
            switch value {
            case .string(let string): string
            case .int(let int): int
            case .double(let double): double
            case .bool(let bool): bool
            }
        })
    }
}
```

An adapter is also free to remap `event.name` to whatever vocabulary its backend expects — Firebase, for example, reserves a specific constant for screen views.

## Wiring a screen

```swift
let analytics = ScreenAnalyticsService(trackers: [FirebaseScreenTracker(), ConsoleScreenTracker()])

func onAppear(source: ScreenOpenSource<AppScreen>) {
    analytics.trackScreenOpened("Articles", source: source.analyticsKind)
    analytics.observeStateChanges(of: store, screen: "Articles")
}
```

`trackScreenOpened(_:source:)` sends one `screen_opened` event. `observeStateChanges(of:screen:)` uses the same `withObservationTracking` mechanism ``ScreenStateContainerView`` uses to mirror a store, and sends a `screen_state_changed` event for every subsequent ``ScreenState`` transition — call it once, right where you create or first observe the store. When a transition lands on `.error`, the event also carries the error's `localizedDescription`.

Both ``ScreenState`` and ``ScreenOpenSource`` expose an `analyticsKind` helper — a short, stable, payload-free name for the current case (`"loading"`, `"error"`, `"push"`, `"deep_link"`, ...) — so you can build custom ``ScreenAnalyticsEvent``s yourself for anything the built-in factories don't cover.

## See Also

- ``ScreenAnalyticsService``
- ``ScreenAnalyticsTracker``
- ``ScreenAnalyticsEvent``
