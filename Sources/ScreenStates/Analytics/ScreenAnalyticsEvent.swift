import Foundation

/// A single analytics event describing something that happened to a screen
/// — it became visible, or its ``ScreenState`` changed — in a
/// backend-agnostic shape a ``ScreenAnalyticsTracker`` can forward to any
/// analytics SDK.
public struct ScreenAnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: [String: AnalyticsValue]

    public init(name: String, parameters: [String: AnalyticsValue] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

extension ScreenAnalyticsEvent {
    /// The default event for a screen becoming visible. Pass `source` (for
    /// example a ``ScreenOpenSource``'s ``ScreenOpenSource/analyticsKind``)
    /// to also record how it got there.
    public static func screenOpened(screen: String, source: String? = nil) -> ScreenAnalyticsEvent {
        var parameters: [String: AnalyticsValue] = ["screen": .string(screen)]
        if let source {
            parameters["source"] = .string(source)
        }
        return ScreenAnalyticsEvent(name: "screen_opened", parameters: parameters)
    }

    /// The default event for a ``ScreenState`` transition, `from` and `to`
    /// being a state's ``ScreenState/analyticsKind``. `errorDescription` is
    /// typically only passed when `to == "error"`.
    public static func screenStateChanged(
        screen: String,
        from: String,
        to: String,
        errorDescription: String? = nil
    ) -> ScreenAnalyticsEvent {
        var parameters: [String: AnalyticsValue] = [
            "screen": .string(screen),
            "from": .string(from),
            "to": .string(to)
        ]
        if let errorDescription {
            parameters["error"] = .string(errorDescription)
        }
        return ScreenAnalyticsEvent(name: "screen_state_changed", parameters: parameters)
    }
}

extension ScreenState {
    /// A short, stable, analytics-friendly name for the case, ignoring any
    /// payload — `"empty"`, `"loading"`, `"data"`, or `"error"`.
    public var analyticsKind: String {
        switch self {
        case .empty: "empty"
        case .loading: "loading"
        case .data: "data"
        case .error: "error"
        }
    }
}

extension ScreenOpenSource {
    /// A short, stable, analytics-friendly name for the case, ignoring any
    /// payload — `"push"`, `"pop"`, `"presented"`, `"deep_link"`,
    /// `"shortcut"`, `"tab_selection"`, or `"unknown"`.
    public var analyticsKind: String {
        switch self {
        case .push: "push"
        case .pop: "pop"
        case .presented: "presented"
        case .deepLink: "deep_link"
        case .shortcut: "shortcut"
        case .tabSelection: "tab_selection"
        case .unknown: "unknown"
        }
    }
}
