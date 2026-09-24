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
    /// `screen_state_changed` event named `screen`, plus a
    /// `screen_load_duration` event (see ``ScreenAnalyticsEvent/screenLoadDuration(screen:outcome:milliseconds:)``)
    /// every time `.loading` is left for `.data`, `.empty`, or `.error`.
    /// Uses `withObservationTracking` the same way
    /// ``ScreenStateContainerView`` mirrors a store — call it once, e.g.
    /// right after creating the store.
    public func observeStateChanges<Value>(of store: ScreenStateStore<Value>, screen: String) {
        let tracking = TransitionTracking(
            kind: store.state.analyticsKind,
            loadingStartedAt: store.state.isLoading ? .now : nil
        )
        observe(store, screen: screen, tracking: tracking)
    }

    private func observe<Value>(_ store: ScreenStateStore<Value>, screen: String, tracking: TransitionTracking) {
        withObservationTracking {
            _ = store.state
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                let newKind = store.state.analyticsKind
                if newKind != tracking.kind {
                    self.track(.screenStateChanged(
                        screen: screen,
                        from: tracking.kind,
                        to: newKind,
                        errorDescription: store.state.error?.localizedDescription
                    ))
                    if newKind == "loading" {
                        tracking.loadingStartedAt = .now
                    } else if let startedAt = tracking.loadingStartedAt, tracking.kind == "loading" {
                        self.track(.screenLoadDuration(
                            screen: screen,
                            outcome: newKind,
                            milliseconds: startedAt.duration(to: .now).milliseconds
                        ))
                        tracking.loadingStartedAt = nil
                    }
                    tracking.kind = newKind
                }
                self.observe(store, screen: screen, tracking: tracking)
            }
        }
    }
}

/// Boxes the last-seen ``ScreenState/analyticsKind`` and, while it's
/// `"loading"`, when that started, across the recursive re-subscriptions
/// `observe(_:screen:tracking:)` needs to keep tracking a store's changes
/// indefinitely.
@MainActor
private final class TransitionTracking {
    var kind: String
    var loadingStartedAt: ContinuousClock.Instant?

    init(kind: String, loadingStartedAt: ContinuousClock.Instant?) {
        self.kind = kind
        self.loadingStartedAt = loadingStartedAt
    }
}

extension Duration {
    /// The whole number of milliseconds in this duration, truncating any
    /// remainder — plenty of precision for an analytics payload.
    fileprivate var milliseconds: Int {
        let (seconds, attoseconds) = components
        return Int(seconds * 1000) + Int(attoseconds / 1_000_000_000_000_000)
    }
}
