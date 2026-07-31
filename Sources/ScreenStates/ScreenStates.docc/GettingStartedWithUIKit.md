# Getting Started with UIKit

Drive a UIKit screen's four states with ``ScreenStateStore`` and ``ScreenStateContainerView``.

## Overview

``ScreenStateContainerView`` is the UIKit counterpart to ``ScreenStateView``: a `UIView` that swaps its content for the right placeholder based on a ``ScreenState``. Call ``ScreenStateContainerView/bind(to:)`` to keep it in sync with a ``ScreenStateStore``.

```swift
import UIKit
import ScreenStates

final class ArticlesViewController: UIViewController {
    private let store = ScreenStateStore<[Article]>()
    private lazy var container = ScreenStateContainerView<[Article]>(onRetry: { [weak self] in
        Task { await self?.reload() }
    }) { articles in
        let list = ArticleListView(articles: articles) // any UIView you build from `articles`
        return list
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        container.bind(to: store) // keeps container.state in sync with store.state

        Task { await reload() }
    }

    private func reload() async {
        await store.loadCollection { try await api.fetchArticles() }
    }
}
```

`bind(to:)` uses `withObservationTracking` under the hood — the same Observation framework mechanism SwiftUI itself relies on — so the container re-renders automatically whenever `store.state` changes, with no Combine, delegates, or `NotificationCenter` involved.

## Customizing the placeholders

Pass `emptyView`, `loadingView`, and an `errorView` builder to fully replace the defaults:

```swift
ScreenStateContainerView<[Article]>(
    emptyView: MyEmptyView(),
    loadingView: MyLoadingView(),
    errorView: { error in MyErrorView(error: error) },
    content: { articles in ArticleListView(articles: articles) }
)
```

## See Also

- ``ScreenStateStore``
- ``ScreenStateContainerView``
- <doc:GettingStartedWithSwiftUI>
