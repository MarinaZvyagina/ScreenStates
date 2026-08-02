# Tracking How a Screen Was Opened

Change a screen's behavior based on how it came to be visible, with ``ScreenOpenSource``.

## Overview

``ScreenState`` and ``ScreenStateStore`` only model what a screen is showing right now — Empty, Loading, Data, or Error. They don't know, and don't need to know, how the screen got there. ``ScreenOpenSource`` is a separate, independent type for exactly that: was the screen freshly pushed, revealed by popping something off a navigation stack, presented modally, opened from a deep link, or launched from a Home Screen shortcut?

ScreenStates can't detect any of this on its own — there's no `NavigationStack` modifier or UIKit push interception behind ``ScreenOpenSource``. Your app already knows the answer wherever navigation actually happens (a coordinator, a router, a `NavigationStack` path change, `onOpenURL`, a shortcut-item handler), so it passes the value in explicitly.

## A concrete example

The most common reason to care about this: skip a reload when the user is merely returning to a screen that's already showing data, but do reload on a fresh push.

```swift
enum AppScreen {
    case home, articleList, articleDetail
}

@MainActor
final class ArticleListViewModel {
    let store = ScreenStateStore<[Article]>()

    func onAppear(source: ScreenOpenSource<AppScreen>) {
        if source.isPop {
            return // already have data from before — nothing to do
        }
        Task { await store.loadCollection { try await api.fetchArticles() } }
    }
}
```

`source.originatingScreen` gives you the `Screen` that triggered a `.push`, `.pop`, or `.presented` — useful for anything more specific than "was this a pop", like varying copy or analytics by referrer:

```swift
if source.originatingScreen == .home {
    // came straight from the home screen
}
```

## See Also

- ``ScreenOpenSource``
