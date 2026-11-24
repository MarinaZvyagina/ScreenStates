#if canImport(UIKit) && !os(watchOS)
import UIKit
#if canImport(SwiftUI)
import SwiftUI

/// Bridges ``ScreenStatesTheme`` into UIKit's trait system — the UIKit
/// counterpart to SwiftUI's `.screenStatesTheme(_:)` environment value.
/// Set it once via `traitOverrides` on a container view or view
/// controller, and read it back via `traitCollection` anywhere beneath it
/// in the view hierarchy.
///
/// Unlike a handful of built-in traits Apple bridges privately (size
/// class, Dynamic Type, layout direction, …), there's no public API to
/// bridge a *custom* trait like this one automatically to/from SwiftUI's
/// Environment. Confirmed empirically (not just assumed): a theme set via
/// `traitOverrides` on a UIKit ancestor reaches every UIKit descendant,
/// including a `UIHostingController`'s own view, but its SwiftUI content
/// still reads `EnvironmentValues.screenStatesTheme` as `.standard` — the
/// two are entirely separate storage. The same gap exists in reverse: a
/// theme set via `.screenStatesTheme(_:)` in a SwiftUI environment never
/// reaches a UIKit view embedded beneath it through `UIViewRepresentable`.
///
/// On a screen that mixes both paradigms, bridge explicitly at the
/// embedding point instead of relying on either ambient value:
///
/// ```swift
/// // UIKit embedding SwiftUI: apply the theme to the hosted root view.
/// let hosting = UIHostingController(
///     rootView: SomeSwiftUIView().screenStatesTheme(theme)
/// )
///
/// // SwiftUI embedding UIKit: copy the environment value across in
/// // `updateUIView(_:context:)`.
/// func updateUIView(_ uiView: SomeUIKitView, context: Context) {
///     uiView.traitOverrides.screenStatesTheme = context.environment.screenStatesTheme
/// }
/// ```
public struct ScreenStatesThemeTrait: UITraitDefinition {
    public static let defaultValue: ScreenStatesTheme = .standard
}

extension UITraitCollection {
    /// The ``ScreenStatesTheme`` in effect for this trait collection —
    /// ``ScreenStatesTheme/standard`` (no overrides) unless set via
    /// `traitOverrides`.
    public var screenStatesTheme: ScreenStatesTheme {
        self[ScreenStatesThemeTrait.self]
    }
}

extension UITraitOverrides {
    /// Set to theme every default UIKit placeholder beneath this view
    /// (or view controller) in the hierarchy — see
    /// ``ScreenStatesThemeTrait``.
    public var screenStatesTheme: ScreenStatesTheme {
        get { self[ScreenStatesThemeTrait.self] }
        set { self[ScreenStatesThemeTrait.self] = newValue }
    }
}
#endif
#endif
