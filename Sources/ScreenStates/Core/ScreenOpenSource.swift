import Foundation

/// How a screen came to be visible: freshly pushed, revealed by popping a
/// later screen off a navigation stack, presented modally, or opened from
/// outside the app entirely.
///
/// ScreenStates has no way to detect this on its own — there's no
/// `NavigationStack` modifier or UIKit push interception behind this type.
/// Pass it in wherever your app already knows the answer (a coordinator, a
/// router, a `NavigationStack` path change, `onOpenURL`, a shortcut-item
/// handler), and switch on it to change a screen's behavior:
///
/// ```swift
/// let source: ScreenOpenSource<AppScreen> = .push(from: .home)
///
/// if source.isPop {
///     // returning to an existing screen — reuse what's already loaded
/// } else {
///     Task { await store.loadCollection { try await api.fetchArticles() } }
/// }
/// ```
public enum ScreenOpenSource<Screen> {
    /// Freshly pushed onto a navigation stack from `Screen`.
    case push(from: Screen)
    /// Revealed again because `Screen`, which was on top of it, was popped.
    case pop(from: Screen)
    /// Presented modally (a sheet, a full-screen cover) from `Screen`.
    case presented(from: Screen)
    /// Opened by resolving a deep link.
    case deepLink(URL)
    /// Opened from a Home Screen quick action or App Shortcut.
    case shortcut(id: String)
    /// Selected as a tab.
    case tabSelection
    /// The source wasn't recorded, or doesn't fit the other cases.
    case unknown
}

extension ScreenOpenSource {
    /// `true` only for `.pop` — the screen already existed and is simply
    /// being shown again, as opposed to being opened fresh.
    public var isPop: Bool {
        if case .pop = self { true } else { false }
    }

    /// The screen that triggered this one for `.push`, `.pop`, and
    /// `.presented`; `nil` for every other case.
    public var originatingScreen: Screen? {
        switch self {
        case .push(let screen), .pop(let screen), .presented(let screen):
            screen
        case .deepLink, .shortcut, .tabSelection, .unknown:
            nil
        }
    }
}

extension ScreenOpenSource: Equatable where Screen: Equatable {}
extension ScreenOpenSource: Hashable where Screen: Hashable {}
extension ScreenOpenSource: Sendable where Screen: Sendable {}
