#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Sugar for `ScreenStateView(state, onRetry:content:)`, usable at the
    /// end of a modifier chain instead of wrapping the whole call site in
    /// an initializer. `self` is discarded — the result replaces it with a
    /// ``ScreenStateView``, exactly as if you'd constructed one directly.
    ///
    /// ```swift
    /// EmptyView()
    ///     .screenState(store.state, onRetry: reload) { articles in
    ///         List(articles) { ArticleRow($0) }
    ///     }
    /// ```
    public func screenState<Value, Content: View>(
        _ state: ScreenState<Value>,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) -> some View {
        ScreenStateView(state, onRetry: onRetry, content: content)
    }

    /// Sugar for the fully-customized
    /// `ScreenStateView(_:content:empty:loading:error:)`.
    public func screenState<Value, Content: View, EmptyContent: View, LoadingContent: View, ErrorContent: View>(
        _ state: ScreenState<Value>,
        @ViewBuilder content: @escaping (Value) -> Content,
        @ViewBuilder empty: @escaping () -> EmptyContent,
        @ViewBuilder loading: @escaping () -> LoadingContent,
        @ViewBuilder error: @escaping (Error) -> ErrorContent
    ) -> some View {
        ScreenStateView(state, content: content, empty: empty, loading: loading, error: error)
    }
}
#endif
