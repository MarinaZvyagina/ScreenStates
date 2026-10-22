#if canImport(UIKit) && !os(watchOS)
import UIKit
import Observation

/// Notified when a store bound via ``ScreenStateContainerView/bind(to:)``'s
/// `isRefreshing`/`refreshError` change — the UIKit counterpart to reading
/// them directly in a SwiftUI view's body, which re-renders on any
/// ``ScreenStateStore`` property access automatically. `state` itself is
/// already mirrored by `bind(to:)`'s own `state` property; this covers the
/// two properties that doesn't.
///
/// Default (empty) implementations are provided, so a conformer only needs
/// to implement whichever callback it actually cares about.
@MainActor
public protocol ScreenStateContainerViewDelegate: AnyObject {
    /// Called whenever the bound store's `isRefreshing` changes.
    func screenStateContainerViewDidUpdateIsRefreshing(_ isRefreshing: Bool)
    /// Called whenever the bound store's `refreshError` changes.
    func screenStateContainerViewDidUpdateRefreshError(_ error: Error?)
}

extension ScreenStateContainerViewDelegate {
    public func screenStateContainerViewDidUpdateIsRefreshing(_ isRefreshing: Bool) {}
    public func screenStateContainerViewDidUpdateRefreshError(_ error: Error?) {}
}

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

    /// Notified when the bound store's `isRefreshing`/`refreshError`
    /// change — see ``ScreenStateContainerViewDelegate``.
    public weak var delegate: (any ScreenStateContainerViewDelegate)?

    private let emptyView: UIView
    private let loadingView: UIView
    private let errorViewProvider: (Error) -> UIView
    private let contentProvider: (Value) -> UIView

    /// Bumped by every ``bind(to:)`` call; the recursive re-subscription
    /// inside `observe(_:generation:)` drops itself once its captured
    /// generation no longer matches, instead of continuing to mirror a
    /// store a later `bind(to:)` call has since replaced.
    private var bindGeneration = 0
    private var currentContentView: UIView?
    private var lastIsRefreshing = false
    private var lastRefreshError: Error?

    /// Uses the built-in Empty / Loading / Error placeholders.
    /// - Parameters:
    ///   - onRetry: wired to the default error view's Retry button.
    ///   - contentProvider: builds the view shown for ``ScreenState/data(_:)``.
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

    /// Mirrors `store.state` into this view, and `store.isRefreshing`/
    /// `store.refreshError` into ``delegate``, using
    /// `withObservationTracking` — the Observation framework's way of
    /// bridging `@Observable` types into non-SwiftUI code.
    ///
    /// Each property gets its own independent tracking chain rather than
    /// one shared one: `withObservationTracking`'s `onChange` fires at
    /// most once per registration, and `refresh(_:)` writes all three of
    /// `refreshError`, `isRefreshing`, and (via the operation's `Task`)
    /// `refreshError` again in quick succession. A single shared
    /// registration can only catch the first of those before it needs
    /// re-arming — which, being itself async, can't keep up — silently
    /// dropping the rest. Independent chains each only have to keep up
    /// with changes to their own property.
    public func bind(to store: ScreenStateStore<Value>) {
        bindGeneration += 1
        lastIsRefreshing = store.isRefreshing
        lastRefreshError = store.refreshError
        observeState(store, generation: bindGeneration)
        observeIsRefreshing(store, generation: bindGeneration)
        observeRefreshError(store, generation: bindGeneration)
    }

    private func observeState(_ store: ScreenStateStore<Value>, generation: Int) {
        withObservationTracking {
            state = store.state
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.bindGeneration == generation else { return }
                self.observeState(store, generation: generation)
            }
        }
    }

    private func observeIsRefreshing(_ store: ScreenStateStore<Value>, generation: Int) {
        withObservationTracking {
            let isRefreshing = store.isRefreshing
            if isRefreshing != lastIsRefreshing {
                lastIsRefreshing = isRefreshing
                delegate?.screenStateContainerViewDidUpdateIsRefreshing(isRefreshing)
            }
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.bindGeneration == generation else { return }
                self.observeIsRefreshing(store, generation: generation)
            }
        }
    }

    private func observeRefreshError(_ store: ScreenStateStore<Value>, generation: Int) {
        withObservationTracking {
            let refreshError = store.refreshError
            if !Self.errorsEqual(refreshError, lastRefreshError) {
                lastRefreshError = refreshError
                delegate?.screenStateContainerViewDidUpdateRefreshError(refreshError)
            }
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.bindGeneration == generation else { return }
                self.observeRefreshError(store, generation: generation)
            }
        }
    }

    /// `Error` isn't `Equatable` (it's an existential), so this bridges to
    /// `NSError` for comparison — the same trick ``ScreenState``'s own
    /// `Equatable` conformance uses for its `.error` case.
    private static func errorsEqual(_ lhs: Error?, _ rhs: Error?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (lhs?, rhs?): (lhs as NSError) == (rhs as NSError)
        default: false
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
            viewToShow.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        #if os(tvOS)
        // Swapping content programmatically (rather than through a natural
        // view controller transition) doesn't automatically nudge the focus
        // engine, so the Siri Remote can appear stuck on a view that was
        // just removed — e.g. going from Error (focused on Retry) to
        // Loading or Empty, which have nothing focusable at all.
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        #endif
    }

    #if os(tvOS)
    /// Delegates to whichever placeholder is currently shown, so the focus
    /// engine lands on its preferred target (e.g. the Error view's Retry
    /// button) instead of guessing.
    public override var preferredFocusEnvironments: [UIFocusEnvironment] {
        currentContentView.map { [$0] } ?? super.preferredFocusEnvironments
    }
    #endif
}
#endif
