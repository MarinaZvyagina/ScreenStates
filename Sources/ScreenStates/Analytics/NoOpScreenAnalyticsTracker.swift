/// A ``ScreenAnalyticsTracker`` that does nothing — a harmless placeholder
/// for tests, SwiftUI Previews, or a build configuration where you don't
/// want to wire up a real analytics backend yet.
///
/// ```swift
/// let analytics = ScreenAnalyticsService(trackers: [NoOpScreenAnalyticsTracker()])
/// ```
public struct NoOpScreenAnalyticsTracker: ScreenAnalyticsTracker {
    public init() {}

    public func track(_ event: ScreenAnalyticsEvent) {}
}
