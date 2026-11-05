# Pagination

Load a collection page by page with ``ScreenStateStore/loadNextPage(_:)``, appending each page to what's already on screen instead of replacing it.

## Overview

`load(_:)`/`loadCollection(_:)` fetch everything a screen needs in one shot; `refresh(_:)`/`refreshCollection(_:)` refetch all of it while keeping the old data on screen in the meantime. Neither fits a third common shape: a list that grows one page at a time as the user scrolls, where each new page should be *appended* to what's already there, not replace it. ``ScreenStateStore/loadNextPage(_:)`` is that third shape, available when `Value: RangeReplaceableCollection`.

## Loading more pages

```swift
struct ArticlesListScreen: View {
    @State private var store = ScreenStateStore<[Article]>()
    @State private var nextPage = 2 // page 1 is already loaded by reload()

    var body: some View {
        ScreenStateView(store.state, onRetry: reload) { articles in
            List(articles) { article in
                Text(article.title)
                    .task {
                        if article.id == articles.last?.id {
                            await loadMore()
                        }
                    }
            }
        }
        .task { await reload() }
    }

    private func reload() async {
        await store.loadCollection { try await api.fetchArticles(page: 1) }
    }

    private func loadMore() async {
        await store.loadNextPage { try await api.fetchArticles(page: nextPage) }
        nextPage += 1
    }
}
```

`loadCollection(_:)` fetches the first page as usual; `loadNextPage(_:)` fetches every page after that, appending its result to the existing `.data` collection. It requires `state` to already be `.data` — call `loadCollection(_:)` first — and does nothing otherwise, so an accidental early call (before the first page has loaded) is a no-op rather than a crash or a replaced state.

## isLoadingNextPage and loadNextPageError

``ScreenStateStore/isLoadingNextPage`` is `true` for the duration of a `loadNextPage(_:)` call — show a small spinner at the bottom of the list while it's `true`, the pagination equivalent of ``ScreenStateStore/isRefreshing``.

If the page fetch fails, `state` is left exactly as it was (the pages already loaded stay on screen) and the error is reported through ``ScreenStateStore/loadNextPageError`` instead of replacing `state` with `.error` — the same shape as ``ScreenStateStore/refresh(_:)``/``ScreenStateStore/refreshError``:

```swift
if let error = store.loadNextPageError {
    Text("Couldn't load more: \(error.localizedDescription)")
}
```

`loadNextPageError` is cleared at the start of the next `loadNextPage(_:)` call, so a retried page fetch that succeeds clears a stale failure automatically.

## Overlapping calls

`loadNextPage(_:)` follows the same overlapping-call rule as every other `load`/`refresh`-family method (see <doc:ConcurrencyAndCancellation>): if a second call — another `loadNextPage(_:)`, or a `load`/`refresh`/`loadCollection`/`refreshCollection` elsewhere — starts before an earlier `loadNextPage(_:)`'s fetch resolves, the earlier call's result is silently dropped instead of being appended out of order.

## See Also

- ``ScreenStateStore``
- <doc:ConcurrencyAndCancellation>
- <doc:TrackingAnalytics>
