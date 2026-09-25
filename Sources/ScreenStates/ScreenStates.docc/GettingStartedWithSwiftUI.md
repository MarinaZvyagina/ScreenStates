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

If you'd rather not wrap the whole call site in an initializer, `.screenState(_:onRetry:content:)` is the same thing as a view modifier:

```swift
EmptyView()
    .screenState(store.state, onRetry: reload) { articles in
        List(articles) { article in Text(article.title) }
    }
```

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

## Refreshing without losing data

`loadCollection(_:)` always shows `.loading` first, which is right for the initial fetch but wrong for pull-to-refresh — the list shouldn't disappear behind a spinner while it's being refetched. Use `refreshCollection(_:)` instead: it keeps the current `.data` on screen while the operation runs, and leaves it there if the operation fails instead of switching to `.error`:

```swift
List(articles) { article in
    Text(article.title)
}
.refreshable {
    await store.refreshCollection { try await api.fetchArticles() }
}
```

`store.isRefreshing` is `true` for the duration; a failure is reported via `store.refreshError` rather than by discarding `state`, so the list stays visible and you can surface the error separately (a toast, for example).

## Retrying on failure

For a flaky call worth retrying automatically before showing an error, use ``ScreenStateStore/loadWithRetry(maxAttempts:backoff:_:)`` instead of `loadCollection(_:)`:

```swift
await store.loadWithRetry(maxAttempts: 3) {
    try await api.fetchArticles()
}
```

`state` stays `.loading` across every attempt; only the final failure, once `maxAttempts` is exhausted, switches it to `.error`. `backoff` is called with the attempt number that just failed and returns how long to wait before the next try, defaulting to doubling from one second.

## Previewing a screen in a specific state

Give a preview-friendly screen its store via `init` instead of owning it in `@State`, and pin that store to one state with a `preview`-prefixed factory instead of driving it through a real `loadCollection(_:)` call:

```swift
struct ArticlesScreen: View {
    let store: ScreenStateStore<[Article]>

    var body: some View {
        ScreenStateView(store.state) { articles in
            List(articles) { Text($0.title) }
        }
    }
}

#Preview("Empty") {
    ArticlesScreen(store: .previewEmpty)
}
#Preview("Error") {
    ArticlesScreen(store: .previewError("Couldn't reach the server"))
}
```

``ScreenStateStore/previewError(_:)`` uses a built-in ``ScreenStatePreviewError`` so a preview doesn't need a placeholder `Error` type of its own. ``ScreenStateStore/preview(_:)`` accepts any ``ScreenState`` directly for anything the named helpers don't cover.

## See Also

- ``ScreenStateStore``
- ``ScreenStateView``
- <doc:GettingStartedWithUIKit>
