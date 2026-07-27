#if canImport(SwiftUI)
import SwiftUI

/// Renders the right content for a ``ScreenState``, switching between
/// Empty / Loading / Data / Error automatically.
///
/// ```swift
/// ScreenStateView(store.state) { articles in
///     List(articles) { ArticleRow($0) }
/// }
/// ```
public struct ScreenStateView<Value, Content: View>: View {
    private let state: ScreenState<Value>
    private let content: (Value) -> Content
    private let emptyView: AnyView
    private let loadingView: AnyView
    private let errorView: (Error) -> AnyView

    /// Uses the built-in Empty / Loading / Error placeholders.
    /// - Parameter onRetry: wired to the default error view's Retry button.
    public init(
        _ state: ScreenState<Value>,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.content = content
        emptyView = AnyView(ScreenStateDefaultEmptyView())
        loadingView = AnyView(ScreenStateDefaultLoadingView())
        errorView = { AnyView(ScreenStateDefaultErrorView(error: $0, onRetry: onRetry)) }
    }

    /// Fully customizes the Empty / Loading / Error placeholders.
    public init<EmptyContent: View, LoadingContent: View, ErrorContent: View>(
        _ state: ScreenState<Value>,
        @ViewBuilder content: @escaping (Value) -> Content,
        @ViewBuilder empty: @escaping () -> EmptyContent,
        @ViewBuilder loading: @escaping () -> LoadingContent,
        @ViewBuilder error: @escaping (Error) -> ErrorContent
    ) {
        self.state = state
        self.content = content
        emptyView = AnyView(empty())
        loadingView = AnyView(loading())
        errorView = { AnyView(error($0)) }
    }

    public var body: some View {
        switch state {
        case .empty:
            emptyView
        case .loading:
            loadingView
        case .data(let value):
            content(value)
        case .error(let error):
            errorView(error)
        }
    }
}
#endif
