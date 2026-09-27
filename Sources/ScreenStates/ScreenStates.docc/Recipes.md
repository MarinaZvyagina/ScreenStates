# Recipes

Common multi-screen patterns built on ``ScreenStateStore`` and ``ScreenStateView``.

## Overview

A single ``ScreenStateStore`` models one screen. Real apps have several screens at once — a list next to a detail, one per tab, a sidebar next to its content — each of which typically wants its *own* store, scoped to exactly what that screen shows. This article walks through three common shapes for that.

## List + Detail

Give the list screen and the detail screen their own store, each scoped to what that screen actually needs — a `[Article]` summary for the list, a full `Article` for the detail — rather than trying to stretch one store to cover both:

```swift
struct ArticlesListScreen: View {
    @State private var store = ScreenStateStore<[Article]>()

    var body: some View {
        NavigationStack {
            ScreenStateView(store.state, onRetry: reload) { articles in
                List(articles) { article in
                    NavigationLink(article.title, value: article.id)
                }
            }
            .navigationDestination(for: Article.ID.self) { id in
                ArticleDetailScreen(articleID: id)
            }
            .task { await reload() }
        }
    }

    private func reload() async {
        await store.loadCollection { try await api.fetchArticles() }
    }
}

struct ArticleDetailScreen: View {
    let articleID: Article.ID
    @State private var store = ScreenStateStore<Article>()

    var body: some View {
        ScreenStateView(store.state, onRetry: reload) { article in
            ArticleDetailView(article: article)
        }
        .task(id: articleID) { await reload() }
    }

    private func reload() async {
        await store.load { try await api.fetchArticle(id: articleID) }
    }
}
```

`navigationDestination(for:)` creates a fresh `ArticleDetailScreen` — and so a fresh store, starting at the default `.loading` — every time a row is tapped, so there's no manual reset to write. `.task(id: articleID)` (rather than a plain `.task`) is what makes this reusable in the next recipe below, where the same screen's `articleID` can change *without* the view itself being recreated.

## One Store per Tab

Give each tab's screen its own `@State` store. `TabView` preserves each tab's view identity across switches, so the store — and the `.task` that loads it — is created once and lives for as long as the tab does, not recreated every time the user switches back to it:

```swift
struct RootTabView: View {
    var body: some View {
        TabView {
            ArticlesTab()
                .tabItem { Label("Articles", systemImage: "newspaper") }
            ProfileTab()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}

struct ArticlesTab: View {
    @State private var store = ScreenStateStore<[Article]>()

    var body: some View {
        NavigationStack {
            ScreenStateView(store.state, onRetry: reload) { articles in
                List(articles) { Text($0.title) }
            }
            .task { await reload() }
        }
    }

    private func reload() async {
        await store.loadCollection { try await api.fetchArticles() }
    }
}
```

Switching away from and back to a tab shows whatever `store.state` already holds — no flash back to `.loading`. If the data can go stale while another tab is active, wire up `refreshCollection(_:)` (see <doc:GettingStartedWithSwiftUI>) instead of relying on the initial `.task` alone.

## Master-Detail with NavigationSplitView

`NavigationSplitView` shows the sidebar and detail columns side by side, so — unlike the pushed detail screen above — selecting a different row updates the *same* detail view instance's `articleID` rather than creating a new one. This is exactly why the detail screen from **List + Detail** used `.task(id: articleID)`: it cancels and restarts the load whenever `articleID` changes, which a plain `.task` would miss.

```swift
struct ArticlesSplitView: View {
    @State private var listStore = ScreenStateStore<[Article]>()
    @State private var selection: Article.ID?

    var body: some View {
        NavigationSplitView {
            ScreenStateView(listStore.state) { articles in
                List(articles, selection: $selection) { article in
                    Text(article.title).tag(article.id)
                }
            }
            .task { await listStore.loadCollection { try await api.fetchArticles() } }
        } detail: {
            if let selection {
                ArticleDetailScreen(articleID: selection) // reused as-is from List + Detail
            } else {
                ContentUnavailableView("Select an Article", systemImage: "newspaper")
            }
        }
    }
}
```

The sidebar list and the detail content are still two independent stores, each following the same "one store, scoped to one screen" shape as the other two recipes — `NavigationSplitView` only changes how they're laid out, not how they're driven.

## See Also

- <doc:GettingStartedWithSwiftUI>
- ``ScreenStateStore``
- ``ScreenStateView``
