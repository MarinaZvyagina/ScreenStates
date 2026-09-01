/// Something that forwards ``ScreenAnalyticsEvent``s to one analytics
/// backend. Implement this once per backend (Firebase, Mixpanel, Amplitude,
/// a debug console logger, ...); ScreenStates ships no concrete
/// implementations itself, so the module stays dependency-free. An adapter
/// is free to remap `event.name`/`event.parameters` to whatever shape and
/// vocabulary its backend expects.
///
/// ```swift
/// struct FirebaseScreenTracker: ScreenAnalyticsTracker {
///     func track(_ event: ScreenAnalyticsEvent) {
///         Analytics.logEvent(event.name, parameters: event.parameters.mapValues { value in
///             switch value {
///             case .string(let string): string
///             case .int(let int): int
///             case .double(let double): double
///             case .bool(let bool): bool
///             }
///         })
///     }
/// }
/// ```
@MainActor
public protocol ScreenAnalyticsTracker {
    func track(_ event: ScreenAnalyticsEvent)
}
