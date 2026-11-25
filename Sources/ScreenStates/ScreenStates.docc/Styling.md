# Styling

The built-in style variants, alternative Loading placeholders, and the theming configuration point — everything beyond the out-of-the-box defaults for tuning how a placeholder looks without writing a fully custom one.

## Overview

Every default placeholder ships two independent levers: a **style** (how big a footprint it expects to own) and, in SwiftUI, a **theme** (what color/font it uses). On top of the default spinner, two alternative Loading placeholders cover the other common shapes a loading state takes: a pulsing skeleton, and a redacted mirror of the real content.

## `.compact` style

``ScreenStatePlaceholderStyle`` controls how much space a default placeholder expects to fill. Every default placeholder's initializer takes a `style:` parameter, defaulting to `.standard` — the full-screen treatment: a full-size icon, and, for the Loading spinner, filling all available space.

Pass `.compact` to embed the same placeholder in a card or section instead of a whole screen: a smaller icon, smaller text, and — for the Loading spinner — no more forcing itself to fill the available space:

```swift
ScreenStateDefaultEmptyView(style: .compact)
ScreenStateDefaultLoadingUIView(style: .compact)
```

`.compact` always keeps a vertical icon-above-text layout, regardless of the device's orientation — a card's size is dictated by the card, not the device, unlike the automatic landscape-iPhone icon-beside-text switch `.standard` makes on its own.

## Alternative Loading placeholders

``ScreenStateDefaultLoadingView``/``ScreenStateDefaultLoadingUIView`` — the spinner — are what every default-wired `ScreenStateView`/`ScreenStateContainerView`/`ScreenStateViewController` shows. Two opt-in alternatives cover the other common shapes a loading state takes:

- ``ScreenStateShimmerLoadingView``/``ScreenStateShimmerLoadingUIView``: a pulsing skeleton of a circular avatar plus two text-line placeholders, for a generic "something's coming" look that doesn't need to know the real content's shape.
- ``ScreenStateRedactedLoadingView``: renders your real content view through SwiftUI's `.redacted(reason: .placeholder)`, so the placeholder mirrors the exact shape of the content it's standing in for. SwiftUI-only — `redacted(reason:)` has no UIKit equivalent.

```swift
ScreenStateShimmerLoadingView()

ScreenStateRedactedLoadingView {
    ArticleRow(article: .placeholder)
}
```

Both respect Reduce Motion and Increase Contrast the same way the default spinner does; see <doc:Accessibility>.

## Theming

``ScreenStatesTheme`` lets an app theme every default placeholder at once — `tint`, `titleFont`, and `messageFont` — instead of passing a fully custom placeholder view at every call site. Any property left `nil` (the default, via ``ScreenStatesTheme/standard``) keeps the built-in gradient/font. Increase Contrast still wins over `tint` regardless, in both paradigms below — it's an accessibility need, not a branding preference.

### SwiftUI

Set a theme via `View.screenStatesTheme(_:)` on a container view, and every default placeholder beneath it in the view hierarchy (including ``ScreenStateShimmerLoadingView``) picks it up through SwiftUI's `Environment`:

```swift
MyScreenView()
    .screenStatesTheme(ScreenStatesTheme(tint: .indigo, titleFont: .title2, messageFont: .callout))
```

### UIKit

``ScreenStatesThemeTrait`` is the UIKit counterpart, using UIKit's trait system in place of an `Environment`. Set it once via `traitOverrides` on a container view or view controller, and every default UIKit placeholder beneath it picks it up the same way, through `traitCollection`:

```swift
someContainerView.traitOverrides.screenStatesTheme = ScreenStatesTheme(tint: .indigo)
```

Only `tint` carries over on the UIKit side — there's no public `Font` → `UIFont` bridging API, so `titleFont`/`messageFont` stay SwiftUI-only.

### Mixing both paradigms

A custom trait like ``ScreenStatesThemeTrait`` isn't automatically bridged to or from SwiftUI's `Environment` the way a few of Apple's own built-in traits are. On a screen that embeds one paradigm inside the other — a `UIHostingController` in a UIKit navigation stack, or a UIKit view wrapped in `UIViewRepresentable` inside a SwiftUI screen — set the theme explicitly at the embedding point rather than relying on either ambient value to cross over on its own. See ``ScreenStatesThemeTrait``'s documentation for the exact pattern in both directions.

## See Also

- ``ScreenStateDefaultEmptyView``
- ``ScreenStateDefaultLoadingView``
- ``ScreenStateDefaultErrorView``
- ``ScreenStatesThemeTrait``
- <doc:Accessibility>
