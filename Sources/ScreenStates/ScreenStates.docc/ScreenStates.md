# ``ScreenStates``

Give any screen a standard `Empty` / `Loading` / `Data` / `Error` state, usable from both UIKit and SwiftUI.

## Overview

Every screen that loads data has the same four states: **Empty**, **Loading**, **Data**, and **Error**. ScreenStates gives you one small, dependency-free type — ``ScreenState`` — to model that, plus ready-to-use SwiftUI and UIKit views that render it, so you stop rebuilding the same `if`/`else` ladder in every screen.

- One generic enum for all four states, usable in any screen, any paradigm.
- Built on the `Observation` framework (`@Observable`) — no Combine, no third-party dependencies.
- Works with SwiftUI (``ScreenStateView``) and UIKit (``ScreenStateContainerView``) from the same store.
- Sensible default placeholders that you can fully replace.

Requires iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+, or visionOS 1.0+, and Swift 6.0. The UIKit types are available on iOS, tvOS, and visionOS — not macOS or watchOS.

## Topics

### Essentials

- <doc:GettingStartedWithSwiftUI>
- <doc:GettingStartedWithUIKit>

### Modeling state

- ``ScreenState``
- ``ScreenStateStore``
- ``ScreenStatePreviewError``

### Navigation context

- <doc:TrackingOpenSource>
- ``ScreenOpenSource``

### Analytics

- <doc:TrackingAnalytics>
- ``ScreenAnalyticsService``
- ``ScreenAnalyticsTracker``
- ``ScreenAnalyticsEvent``
- ``AnalyticsValue``
- ``PrintScreenAnalyticsTracker``
- ``NoOpScreenAnalyticsTracker``

### SwiftUI

- ``ScreenStateView``
- ``ScreenStateDefaultEmptyView``
- ``ScreenStateDefaultLoadingView``
- ``ScreenStateDefaultErrorView``

### UIKit

- ``ScreenStateContainerView``
- ``ScreenStateViewController``
- ``ScreenStateDefaultEmptyUIView``
- ``ScreenStateDefaultLoadingUIView``
- ``ScreenStateDefaultErrorUIView``
