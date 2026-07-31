# Getting Started with SwiftUI

Drive a SwiftUI screen's four states with ``ScreenStateStore`` and ``ScreenStateView``.

## Overview

``ScreenStateStore`` is an `@Observable` class that owns a screen's ``ScreenState`` and knows how to run an async load. ``ScreenStateView`` switches on that state, rendering your content only for the `.data` case and a placeholder otherwise.

```swift
import SwiftUI
import ScreenStates

struct ArticlesScreen: View {
    @State private var store = ScreenStateStore<[Article]>()

    var body: some View {
        ScreenStateView(store.state, onRetry: reload) { articles in
            List(articles) { article in
                Text(article.title)
            }
        }
        .task { await reload() }
    }

    private func reload() async {
        await store.loadCollection { try await api.fetchArticles() }
    }
}
```

`store.loadCollection(_:)` sets `.loading`, runs the closure, and maps the outcome to `.data`, `.empty` (when the result is an empty collection), or `.error`. `ScreenStateView` shows the default Loading spinner, Empty placeholder, or Error view — with a working Retry button wired to `onRetry` — automatically.

## Customizing the placeholders

Pass `empty`, `loading`, and `error` view builders to fully replace the defaults:

```swift
ScreenStateView(store.state) { articles in
    ArticleList(articles)
} empty: {
    ContentUnavailableView("No Articles Yet", systemImage: "newspaper")
} loading: {
    ProgressView("Loading articles…")
} error: { error in
    MyErrorBanner(error: error, retry: reload)
}
```

## See Also

- ``ScreenStateStore``
- ``ScreenStateView``
- <doc:GettingStartedWithUIKit>
