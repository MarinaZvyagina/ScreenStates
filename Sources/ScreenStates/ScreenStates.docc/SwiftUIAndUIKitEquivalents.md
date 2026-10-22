# SwiftUI & UIKit Equivalents

A single table matching every SwiftUI-side type to its UIKit counterpart (and calling out the handful with no equivalent at all), for a reader who already knows one paradigm and wants the other's version of the same thing at a glance.

## Overview

``ScreenState`` and ``ScreenStateStore`` are shared — every screen, in either paradigm, is driven by the same store. Everything below that is paradigm-specific: a SwiftUI `View` on one side, a UIKit `UIView`/`UIViewController` on the other, built to behave as close to identically as each paradigm allows.

## The table

| SwiftUI | UIKit | Notes |
|---|---|---|
| ``ScreenStateView`` | ``ScreenStateContainerView`` | Both switch on a `ScreenState` and take the same default-placeholders/fully-customized initializer pair. |
| `View.screenState(_:onRetry:content:)` | — | Modifier-chain sugar for `ScreenStateView`; UIKit has no modifier-chain paradigm to translate it into. ``ScreenStateViewController``'s base-class pattern is the UIKit-idiomatic version of "skip the boilerplate," just expressed as a class to subclass instead of a modifier to chain. |
| — | ``ScreenStateViewController`` | A `UIViewController` base class wrapping a full-bounds ``ScreenStateContainerView`` bound to a store — SwiftUI has no equivalent gap to fill, since a SwiftUI `View` already *is* the lightweight unit `ScreenStateView` composes into, with no separate "screen container" boilerplate to wrap. |
| ``ScreenStateDefaultEmptyView`` | ``ScreenStateDefaultEmptyUIView`` | Same default title/icon, same `.compact` ``ScreenStatePlaceholderStyle``, same accessibility identifier. |
| ``ScreenStateDefaultLoadingView`` | ``ScreenStateDefaultLoadingUIView`` | Same spinner, same Reduce Motion/Increase Contrast handling. |
| ``ScreenStateDefaultErrorView`` | ``ScreenStateDefaultErrorUIView`` | Same Retry button, same focus-engine tuning on tvOS, same connectivity-aware icon. The title ("Something Went Wrong"/"Connection Issue") is SwiftUI-only — UIKit's Error placeholder has no separate title slot. |
| ``ScreenStateShimmerLoadingView`` | ``ScreenStateShimmerLoadingUIView`` | Same pulsing-skeleton shape and animation. |
| ``ScreenStateRedactedLoadingView`` | — | Built on SwiftUI's `.redacted(reason: .placeholder)`, which has no UIKit equivalent to build on. |
| ``ScreenStatesTheme`` / `View.screenStatesTheme(_:)` | — | Environment-based; UIKit has no concept of an inherited environment to theme through, so the UIKit default placeholders keep taking configuration directly through their initializers instead. |
| Reading `store.isRefreshing`/`store.refreshError` directly in `body` | ``ScreenStateContainerViewDelegate`` (or ``ScreenStateViewController``'s `isRefreshingDidChange(_:)`/`refreshErrorDidChange(_:)`) | SwiftUI tracks any property access inside `body` automatically; a `UIView`/`UIViewController` has no `body` to do that in, so these two are reported through a small delegate instead. |

## See Also

- ``ScreenStateStore``
- <doc:GettingStartedWithSwiftUI>
- <doc:GettingStartedWithUIKit>
- <doc:Styling>
