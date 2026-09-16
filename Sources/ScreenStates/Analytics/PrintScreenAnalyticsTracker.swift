/// A ``ScreenAnalyticsTracker`` that prints every event to the console —
/// useful for confirming events fire at the right moments during
/// development, without wiring up a real analytics backend.
///
/// ```swift
/// let analytics = ScreenAnalyticsService(trackers: [PrintScreenAnalyticsTracker()])
/// ```
public struct PrintScreenAnalyticsTracker: ScreenAnalyticsTracker {
    public init() {}

    public func track(_ event: ScreenAnalyticsEvent) {
        let parameters = event.parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
        print("[ScreenAnalytics] \(event.name)" + (parameters.isEmpty ? "" : " — \(parameters)"))
    }
}
