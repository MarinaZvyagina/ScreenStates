import Foundation
import Observation

/// Fans a ``ScreenAnalyticsEvent`` out to every registered
/// ``ScreenAnalyticsTracker`` (Firebase, Mixpanel, Amplitude, your own
/// backend — mix and match as many as you like) and, optionally, generates
/// `screen_state_changed` events automatically from a ``ScreenStateStore``.
///
/// ```swift
/// let analytics = ScreenAnalyticsService(trackers: [FirebaseScreenTracker(), ConsoleScreenTracker()])
/// analytics.trackScreenOpened("Articles", source: openSource?.analyticsKind)
/// analytics.observeStateChanges(of: store, screen: "Articles")
/// ```
@MainActor
public final class ScreenAnalyticsService {
    private let trackers: [ScreenAnalyticsTracker]

    public init(trackers: [ScreenAnalyticsTracker]) {
        self.trackers = trackers
    }

    /// Forwards `event` to every registered tracker.
    public func track(_ event: ScreenAnalyticsEvent) {
        for tracker in trackers {
            tracker.track(event)
        }
    }

    /// Tracks a screen becoming visible. Pass `source` — for example a
    /// ``ScreenOpenSource``'s ``ScreenOpenSource/analyticsKind`` — to also
    /// record how it got there.
    public func trackScreenOpened(_ screen: String, source: String? = nil) {
        track(.screenOpened(screen: screen, source: source))
    }

    /// Tracks every ``ScreenState`` transition on `store` from now on as a
    /// `screen_state_changed` event named `screen`. Uses
    /// `withObservationTracking` the same way ``ScreenStateContainerView``
    /// mirrors a store — call it once, e.g. right after creating the store.
    public func observeStateChanges<Value>(of store: ScreenStateStore<Value>, screen: String) {
        observe(store, screen: screen, lastKind: LastKind(store.state.analyticsKind))
    }

    private func observe<Value>(_ store: ScreenStateStore<Value>, screen: String, lastKind: LastKind) {
        withObservationTracking {
            _ = store.state
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                let newKind = store.state.analyticsKind
                if newKind != lastKind.value {
                    self.track(.screenStateChanged(
                        screen: screen,
                        from: lastKind.value,
                        to: newKind,
                        errorDescription: store.state.error?.localizedDescription
                    ))
                    lastKind.value = newKind
                }
                self.observe(store, screen: screen, lastKind: lastKind)
            }
        }
    }
}

/// Boxes the last-seen ``ScreenState/analyticsKind`` across the recursive
/// re-subscriptions `observe(_:screen:lastKind:)` needs to keep tracking a
/// store's changes indefinitely.
@MainActor
private final class LastKind {
    var value: String
    init(_ value: String) { self.value = value }
}
