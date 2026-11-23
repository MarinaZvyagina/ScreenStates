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
/// Environment — on a screen that mixes both paradigms (e.g. a
/// `UIHostingController` embedded in a UIKit navigation stack, or vice
/// versa), set both separately.
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
