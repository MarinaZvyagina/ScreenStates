#if canImport(UIKit) && !os(watchOS)
import UIKit
import Observation

/// A `UIView` that swaps its content for the right placeholder based on a
/// ``ScreenState``, mirroring ``ScreenStateView`` from the SwiftUI side.
///
/// ```swift
/// let container = ScreenStateContainerView<[Article]>(onRetry: { viewModel.reload() }) { articles in
///     let list = ArticleListView(articles: articles)
///     return list
/// }
/// container.bind(to: viewModel.store)
/// view.addSubview(container)
/// ```
@MainActor
public final class ScreenStateContainerView<Value>: UIView {
    /// The state currently being rendered. Setting it directly re-renders
    /// synchronously; prefer ``bind(to:)`` to stay in sync with a
    /// ``ScreenStateStore``.
    public var state: ScreenState<Value> = .loading {
        didSet { render() }
    }

    private let emptyView: UIView
    private let loadingView: UIView
    private let errorViewProvider: (Error) -> UIView
    private let contentProvider: (Value) -> UIView
    private var currentContentView: UIView?

    /// Uses the built-in Empty / Loading / Error placeholders.
    /// - Parameter onRetry: wired to the default error view's Retry button.
    public convenience init(
        onRetry: (() -> Void)? = nil,
        content contentProvider: @escaping (Value) -> UIView
    ) {
        self.init(
            emptyView: ScreenStateDefaultEmptyUIView(),
            loadingView: ScreenStateDefaultLoadingUIView(),
            errorView: { ScreenStateDefaultErrorUIView(error: $0, onRetry: onRetry) },
            content: contentProvider
        )
    }

    /// Fully customizes the Empty / Loading / Error placeholders.
    public init(
        emptyView: UIView,
        loadingView: UIView,
        errorView errorViewProvider: @escaping (Error) -> UIView,
        content contentProvider: @escaping (Value) -> UIView
    ) {
        self.emptyView = emptyView
        self.loadingView = loadingView
        self.errorViewProvider = errorViewProvider
        self.contentProvider = contentProvider
        super.init(frame: .zero)
        render()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    /// Mirrors `store.state` into this view using `withObservationTracking`,
    /// the Observation framework's way of bridging `@Observable` types into
    /// non-SwiftUI code.
    public func bind(to store: ScreenStateStore<Value>) {
        observe(store)
    }

    private func observe(_ store: ScreenStateStore<Value>) {
        withObservationTracking {
            state = store.state
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.observe(store)
            }
        }
    }

    private func render() {
        currentContentView?.removeFromSuperview()

        let viewToShow: UIView
        switch state {
        case .empty:
            viewToShow = emptyView
        case .loading:
            viewToShow = loadingView
        case .data(let value):
            viewToShow = contentProvider(value)
        case .error(let error):
            viewToShow = errorViewProvider(error)
        }

        currentContentView = viewToShow
        viewToShow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(viewToShow)
        NSLayoutConstraint.activate([
            viewToShow.topAnchor.constraint(equalTo: topAnchor),
            viewToShow.bottomAnchor.constraint(equalTo: bottomAnchor),
            viewToShow.leadingAnchor.constraint(equalTo: leadingAnchor),
            viewToShow.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
#endif
