import Foundation

/// Convenience factories for pinning a ``ScreenStateStore`` to a specific
/// ``ScreenState`` — most useful in SwiftUI `#Preview` blocks, where you
/// want to see a screen's Empty/Loading/Error/Data appearance without
/// driving it through a real `load(_:)` call.
///
/// ```swift
/// #Preview("Empty") {
///     ArticlesScreen(store: .previewEmpty)
/// }
/// #Preview("Error") {
///     ArticlesScreen(store: .previewError())
/// }
/// ```
extension ScreenStateStore {
    /// A store pinned to `state`, never transitioning on its own.
    public static func preview(_ state: ScreenState<Value>) -> ScreenStateStore<Value> {
        ScreenStateStore(state)
    }

    /// A store pinned to `.loading`.
    public static var previewLoading: ScreenStateStore<Value> {
        preview(.loading)
    }

    /// A store pinned to `.empty`.
    public static var previewEmpty: ScreenStateStore<Value> {
        preview(.empty)
    }

    /// A store pinned to `.data(value)`.
    public static func previewData(_ value: Value) -> ScreenStateStore<Value> {
        preview(.data(value))
    }

    /// A store pinned to `.error`, with a generic ``ScreenStatePreviewError``
    /// so a preview doesn't need a placeholder `Error` type of its own.
    public static func previewError(_ message: String = "Something went wrong") -> ScreenStateStore<Value> {
        preview(.error(ScreenStatePreviewError(message)))
    }
}

/// A generic error for ``ScreenStateStore/previewError(_:)``, so a preview
/// doesn't need its own placeholder `Error` type just to show `.error`.
public struct ScreenStatePreviewError: LocalizedError {
    public let errorDescription: String?

    public init(_ message: String = "Something went wrong") {
        errorDescription = message
    }
}
