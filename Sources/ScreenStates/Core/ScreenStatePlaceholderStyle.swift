/// How much space a default placeholder expects to fill.
///
/// `.standard` (the default for every default placeholder's initializer)
/// assumes the placeholder owns an entire screen: full-size icon, and —
/// for ``ScreenStateDefaultLoadingView``/``ScreenStateDefaultLoadingUIView``
/// — filling all available space. `.compact` sizes the icon and text down
/// and stops forcing itself to fill the available space, so the same
/// placeholder fits inside a card or section instead of taking over the
/// whole screen.
public enum ScreenStatePlaceholderStyle: Sendable, Equatable {
    case standard
    case compact
}
