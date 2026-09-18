# ScreenStates

[![Tests](https://github.com/MarinaZvyagina/ScreenStates/actions/workflows/tests.yml/badge.svg)](https://github.com/MarinaZvyagina/ScreenStates/actions/workflows/tests.yml)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%2B-blue.svg)](#requirements)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/documentation-DocC-blue.svg)](https://marinazvyagina.github.io/ScreenStates/documentation/screenstates/)

Every screen that loads data has the same four states: **Empty**, **Loading**, **Data**, and **Error**. ScreenStates gives you one small, dependency-free type — `ScreenState<Value>` — to model that, plus ready-to-use SwiftUI and UIKit views that render it, so you stop rebuilding the same `if/else` ladder in every screen.

- 🔹 One generic enum for all four states, usable in any screen, any paradigm
- 🔹 Built on the **Observation** framework (`@Observable`) — no Combine, no third-party dependencies
- 🔹 Works with **SwiftUI** (`ScreenStateView`) and **UIKit** (`ScreenStateContainerView`) from the same store
- 🔹 Vibrant, ready-made Empty/Loading/Error placeholders (built on `ContentUnavailableView` and custom gradient views) that you can fully replace
- 🔹 Default placeholders announce every state change to VoiceOver and expose stable accessibility identifiers for XCUITest
- 🔹 Default placeholder text is localized (English + Russian) via a String Catalog
- 🔹 Tested with **Swift Testing**, built with **Swift 6** strict concurrency

<p align="center">
  <img src="Demo/ScreenStatesDemo/Media/demo.gif" alt="ScreenStates demo: a SwiftUI screen and a UIKit screen each cycling through Loading, Empty, Data, and Error" width="340">
</p>

<p align="center"><em>The <a href="Demo/ScreenStatesDemo">demo app</a> — one SwiftUI screen, one UIKit screen, both auto-cycling through all four states.</em></p>

## Requirements

- iOS 17.0+
- Swift 6.0 / Xcode 16+

## Installation — Swift Package Manager

**In Xcode:** File → Add Package Dependencies… → enter the repository URL → select the `ScreenStates` product → Add Package.

**In `Package.swift`:**

```swift
dependencies: [
    .package(url: "https://github.com/<your-account>/ScreenStates.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["ScreenStates"]
    )
]
```

Then, in any file:

```swift
import ScreenStates
```

## The core type

```swift
public enum ScreenState<Value> {
    case empty
    case loading
    case data(Value)
    case error(Error)
}
```

Drive it with `ScreenStateStore`, an `@Observable` class that owns the state and knows how to run an async load:

```swift
let store = ScreenStateStore<[Article]>()

await store.load {
    try await api.fetchArticles()
}
// store.state is now .data([...]) or .error(...)
```

If `Value` is a `Collection` (an array, for example), use `loadCollection(_:)` instead — an empty result is mapped to `.empty` automatically:

```swift
await store.loadCollection {
    try await api.fetchArticles() // [] → .empty, otherwise → .data
}
```

You can also drive the state manually with `setLoading()`, `setEmpty()`, `setData(_:)`, and `setError(_:)`.

### Refreshing without losing data

`load(_:)`/`loadCollection(_:)` always show `.loading` first, which is right for an initial fetch but wrong for pull-to-refresh — the existing list shouldn't vanish behind a spinner just because it's being refetched. Use `refresh(_:)`/`refreshCollection(_:)` instead: they keep whatever is currently in `state` on screen while `operation` runs, and leave it there if `operation` fails instead of switching to `.error`:

```swift
List(articles) { ... }
    .refreshable {
        await store.refreshCollection { try await api.fetchArticles() }
    }
```

While a refresh is in flight, `store.isRefreshing` is `true`; if it fails, `store.state` is untouched and the error is reported via `store.refreshError` instead (so you can show a toast without discarding the list). Both fall back to `load(_:)`/`loadCollection(_:)` automatically when there's no data yet to preserve.

### Previewing a screen in a specific state

Driving a store through a real `load(_:)` call just to see what the Empty or Error placeholder looks like is annoying in a `#Preview`. Give a preview-friendly screen its store via `init` instead of owning it in `@State`, and use the `preview`-prefixed factories to pin that store to one state:

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
#Preview("Data") {
    ArticlesScreen(store: .previewData([.sample]))
}
```

`previewError(_:)` uses a built-in `ScreenStatePreviewError` so you don't need a placeholder `Error` type of your own. `preview(_:)` accepts any `ScreenState` directly for anything the named helpers don't cover.

## How a screen was opened

`ScreenState` only models what a screen is showing right now. `ScreenOpenSource` is a separate, independent type for *how the screen came to be visible* — freshly pushed, popped back to, presented modally, deep-linked, or opened from a Home Screen shortcut — so a screen can change its behavior accordingly (e.g. skip a reload when merely returning to it):

```swift
public enum ScreenOpenSource<Screen> {
    case push(from: Screen)
    case pop(from: Screen)
    case presented(from: Screen)
    case deepLink(URL)
    case shortcut(id: String)
    case tabSelection
    case unknown
}
```

ScreenStates can't detect this on its own — pass it in wherever your app already knows the answer (a coordinator, a router, a `NavigationStack` path change, `onOpenURL`, a shortcut-item handler):

```swift
func onAppear(source: ScreenOpenSource<AppScreen>) {
    if source.isPop {
        return // already have data from before — nothing to do
    }
    Task { await store.loadCollection { try await api.fetchArticles() } }
}
```

## Analytics

ScreenStates can turn screen opens and `ScreenState` transitions into analytics events, without depending on any specific analytics SDK. Implement `ScreenAnalyticsTracker` once per backend you use — Firebase, Mixpanel, Amplitude, your own logging endpoint, a debug console print, whatever — converting the event's backend-agnostic `AnalyticsValue` parameters to that SDK's own format:

```swift
struct ConsoleScreenTracker: ScreenAnalyticsTracker {
    func track(_ event: ScreenAnalyticsEvent) {
        print(event.name, event.parameters)
    }
}
```

Then hand as many trackers as you like to a `ScreenAnalyticsService`, and wire it to a screen:

```swift
let analytics = ScreenAnalyticsService(trackers: [PrintScreenAnalyticsTracker(), FirebaseScreenTracker()])

analytics.trackScreenOpened("Articles", source: openSource?.analyticsKind)
analytics.observeStateChanges(of: store, screen: "Articles")
```

ScreenStates ships two ready-made trackers so you don't have to write `ConsoleScreenTracker` yourself: `PrintScreenAnalyticsTracker` logs every event to the console (handy for confirming events fire at the right moments during development), and `NoOpScreenAnalyticsTracker` silently discards everything (a harmless placeholder for tests, Previews, or a build where you don't want a real backend wired up yet).

`trackScreenOpened(_:source:)` sends one `screen_opened` event. `observeStateChanges(of:screen:)` uses the same `withObservationTracking` mechanism as `ScreenStateContainerView` to watch a `ScreenStateStore` and sends a `screen_state_changed` event (with the error's description, when transitioning to `.error`) for every subsequent transition — call it once, e.g. right where you create the store. Every tracker registered with the service receives every event, so you can fan the same screen out to multiple analytics backends at once.

## Quick start — SwiftUI

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

That's it: `ScreenStateView` shows the default Loading spinner, Empty placeholder, or Error view (with a working Retry button) automatically, and your `content` closure only ever runs for the `.data` case.

If you'd rather not wrap the whole call site in an initializer, `.screenState(_:onRetry:content:)` is the same thing as a modifier:

```swift
EmptyView()
    .screenState(store.state, onRetry: reload) { articles in
        List(articles) { article in Text(article.title) }
    }
```

### Custom Empty / Loading / Error views

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

## Quick start — UIKit

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

`bind(to:)` uses `withObservationTracking` under the hood — the same Observation framework mechanism SwiftUI itself relies on — so `ScreenStateContainerView` re-renders automatically whenever `store.state` changes, with no Combine, delegates, or NotificationCenter involved.

### Custom Empty / Loading / Error views

```swift
ScreenStateContainerView<[Article]>(
    emptyView: MyEmptyView(),
    loadingView: MyLoadingView(),
    errorView: { error in MyErrorView(error: error) },
    content: { articles in ArticleListView(articles: articles) }
)
```

## Demo app

[`Demo/ScreenStatesDemo`](Demo/ScreenStatesDemo) is a runnable two-screen app —
one SwiftUI screen (Rey Skywalker), one UIKit screen (Kylo Ren) — that
auto-cycles through all four states every couple of seconds using the
library's real API. Open `Demo/ScreenStatesDemo/ScreenStatesDemo.xcodeproj`
and run it.

## Documentation

Full API reference and getting-started guides for both paradigms are published at
**[marinazvyagina.github.io/ScreenStates](https://marinazvyagina.github.io/ScreenStates/documentation/screenstates/)**,
generated with DocC. It's regenerated with [`Scripts/generate-docs.sh`](Scripts/generate-docs.sh).

## API reference

| Type | Purpose |
|---|---|
| `ScreenState<Value>` | `.empty`, `.loading`, `.data(Value)`, `.error(Error)`, plus `value`, `error`, `isLoading`, `isEmpty`, `analyticsKind` helpers |
| `ScreenStateStore<Value>` | `@Observable` container: `state`, `load(_:)`, `loadCollection(_:)` (when `Value: Collection`), `refresh(_:)`, `refreshCollection(_:)` (when `Value: Collection`), `isRefreshing`, `refreshError`, `setLoading()`, `setEmpty()`, `setData(_:)`, `setError(_:)`, plus `preview(_:)`, `previewLoading`, `previewEmpty`, `previewData(_:)`, `previewError(_:)` factories for `#Preview` |
| `ScreenStatePreviewError` | Generic `LocalizedError` used by `previewError(_:)` |
| `ScreenStateView<Value, Content>` | SwiftUI container that switches on a `ScreenState` |
| `View.screenState(_:onRetry:content:)` | View-modifier sugar for `ScreenStateView(_:onRetry:content:)` |
| `ScreenStateContainerView<Value>` | UIKit `UIView` container that switches on a `ScreenState`; `bind(to:)` syncs it to a store |
| `ScreenStateDefault{Empty,Loading,Error}View` | Default SwiftUI placeholders |
| `ScreenStateDefault{Empty,Loading,Error}UIView` | Default UIKit placeholders |
| `ScreenOpenSource<Screen>` | `.push`/`.pop`/`.presented(from:)`, `.deepLink(URL)`, `.shortcut(id:)`, `.tabSelection`, `.unknown`, plus `isPop`, `originatingScreen`, `analyticsKind` helpers |
| `ScreenAnalyticsEvent` | Backend-agnostic event: `name`, `parameters: [String: AnalyticsValue]`, plus `.screenOpened(screen:source:)` and `.screenStateChanged(screen:from:to:errorDescription:)` factories |
| `AnalyticsValue` | `.string`/`.int`/`.double`/`.bool` — the primitive parameter values every analytics SDK accepts |
| `ScreenAnalyticsTracker` | Protocol you implement per analytics backend: `track(_ event: ScreenAnalyticsEvent)` |
| `ScreenAnalyticsService` | Fans events out to every registered `ScreenAnalyticsTracker`: `track(_:)`, `trackScreenOpened(_:source:)`, `observeStateChanges(of:screen:)` |
| `PrintScreenAnalyticsTracker` | Ready-made `ScreenAnalyticsTracker` that logs every event to the console |
| `NoOpScreenAnalyticsTracker` | Ready-made `ScreenAnalyticsTracker` that silently discards every event |

## License

Released under the [MIT License](LICENSE).
