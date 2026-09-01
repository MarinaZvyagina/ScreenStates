/// A value in a ``ScreenAnalyticsEvent``'s parameters, restricted to the
/// primitive types every analytics SDK accepts, so a ``ScreenAnalyticsTracker``
/// can convert it to its own format (a Firebase `[String: Any]`, a Mixpanel
/// `[String: MixpanelType]`, a plain JSON payload, ...) without guesswork.
public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}
