#if canImport(SwiftUI)
import SwiftUI

/// Global theming for the default SwiftUI placeholders — set once via
/// `.screenStatesTheme(_:)` on a container view, and every
/// `ScreenStateDefault{Empty,Loading,Error}View`/``ScreenStateShimmerLoadingView``
/// beneath it in the view hierarchy picks it up, instead of an app passing
/// a fully custom placeholder view at every call site just to change a
/// color or font.
///
/// Increase Contrast always wins over a custom `tint`: it's an
/// accessibility need, not a branding preference, so the default
/// placeholders fall back to their solid `.primary` treatment regardless
/// of any theme. There's no UIKit equivalent — UIKit has no concept of an
/// inherited environment, so the UIKit default placeholders keep taking
/// configuration directly through their initializers.
public struct ScreenStatesTheme: Sendable, Equatable {
    /// Replaces the default pink/orange/yellow gradient with a solid
    /// color, when set. `nil` (the default) keeps the built-in gradient.
    public var tint: Color?
    /// Replaces the default title font (used by the Empty placeholder and
    /// the Error placeholder's title), when set. `nil` (the default) keeps
    /// the style-dependent default (`.compact`/`.standard`).
    public var titleFont: Font?
    /// Replaces the default message font (used by the Empty placeholder's
    /// title and the Error placeholder's description), when set. `nil`
    /// (the default) keeps the style-dependent default.
    public var messageFont: Font?

    public init(tint: Color? = nil, titleFont: Font? = nil, messageFont: Font? = nil) {
        self.tint = tint
        self.titleFont = titleFont
        self.messageFont = messageFont
    }

    /// No overrides — every default placeholder keeps its built-in
    /// gradient and style-dependent fonts. The default value of
    /// `EnvironmentValues.screenStatesTheme`.
    public static let standard = ScreenStatesTheme()
}

private struct ScreenStatesThemeKey: EnvironmentKey {
    static let defaultValue = ScreenStatesTheme.standard
}

extension EnvironmentValues {
    public var screenStatesTheme: ScreenStatesTheme {
        get { self[ScreenStatesThemeKey.self] }
        set { self[ScreenStatesThemeKey.self] = newValue }
    }
}

extension View {
    /// Themes every default SwiftUI placeholder beneath this view in the
    /// hierarchy — see ``ScreenStatesTheme``.
    public func screenStatesTheme(_ theme: ScreenStatesTheme) -> some View {
        environment(\.screenStatesTheme, theme)
    }
}
#endif
