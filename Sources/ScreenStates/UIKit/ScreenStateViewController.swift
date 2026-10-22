#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A `UIViewController` base class that owns a ``ScreenStateContainerView``
/// pinned to the view's edges and bound to a ``ScreenStateStore``,
/// wrapping the boilerplate every UIKit screen using ScreenStates
/// otherwise repeats in `viewDidLoad()`.
///
/// ```swift
/// final class ArticlesViewController: ScreenStateViewController<[Article]> {
///     private let articleStore: ScreenStateStore<[Article]>
///
///     init() {
///         let store = ScreenStateStore<[Article]>()
///         articleStore = store
///         super.init(store: store, onRetry: { Task { await store.loadCollection { try await api.fetchArticles() } } }) { articles in
///             ArticleListView(articles: articles)
///         }
///     }
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         Task { await articleStore.loadCollection { try await api.fetchArticles() } }
///     }
/// }
/// ```
@MainActor
open class ScreenStateViewController<Value>: UIViewController, ScreenStateContainerViewDelegate {
    /// The store driving this screen's content.
    public let store: ScreenStateStore<Value>
    private let container: ScreenStateContainerView<Value>

    /// Uses the built-in Empty / Loading / Error placeholders.
    /// - Parameters:
    ///   - store: the store driving this screen's content.
    ///   - onRetry: wired to the default error view's Retry button.
    ///   - contentProvider: builds the view shown for ``ScreenState/data(_:)``.
    public init(
        store: ScreenStateStore<Value>,
        onRetry: (() -> Void)? = nil,
        content contentProvider: @escaping (Value) -> UIView
    ) {
        self.store = store
        container = ScreenStateContainerView(onRetry: onRetry, content: contentProvider)
        super.init(nibName: nil, bundle: nil)
    }

    /// Fully customizes the Empty / Loading / Error placeholders.
    public init(
        store: ScreenStateStore<Value>,
        emptyView: UIView,
        loadingView: UIView,
        errorView errorViewProvider: @escaping (Error) -> UIView,
        content contentProvider: @escaping (Value) -> UIView
    ) {
        self.store = store
        container = ScreenStateContainerView(
            emptyView: emptyView,
            loadingView: loadingView,
            errorView: errorViewProvider,
            content: contentProvider
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        container.delegate = self
        container.bind(to: store)
    }

    /// Called whenever `store.isRefreshing` changes. Does nothing by
    /// default — override to react to it (e.g. showing a refresh
    /// spinner overlaid on the existing content).
    open func isRefreshingDidChange(_ isRefreshing: Bool) {}

    /// Called whenever `store.refreshError` changes. Does nothing by
    /// default — override to react to it (e.g. showing a toast).
    open func refreshErrorDidChange(_ error: Error?) {}

    public func screenStateContainerViewDidUpdateIsRefreshing(_ isRefreshing: Bool) {
        isRefreshingDidChange(isRefreshing)
    }

    public func screenStateContainerViewDidUpdateRefreshError(_ error: Error?) {
        refreshErrorDidChange(error)
    }

    #if os(tvOS)
    /// Delegates to ``container``, which in turn delegates to whichever
    /// placeholder is currently shown.
    open override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [container]
    }
    #endif
}
#endif
