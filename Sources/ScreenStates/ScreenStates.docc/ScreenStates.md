# ``ScreenStates``

Give any iOS screen a standard `Empty` / `Loading` / `Data` / `Error` state, usable from both UIKit and SwiftUI.

## Overview

Every screen that loads data has the same four states: **Empty**, **Loading**, **Data**, and **Error**. ScreenStates gives you one small, dependency-free type — ``ScreenState`` — to model that, plus ready-to-use SwiftUI and UIKit views that render it, so you stop rebuilding the same `if`/`else` ladder in every screen.

- One generic enum for all four states, usable in any screen, any paradigm.
- Built on the `Observation` framework (`@Observable`) — no Combine, no third-party dependencies.
- Works with SwiftUI (``ScreenStateView``) and UIKit (``ScreenStateContainerView``) from the same store.
- Sensible default placeholders that you can fully replace.

Requires iOS 17.0+ and Swift 6.0.

## Topics

### Essentials

- <doc:GettingStartedWithSwiftUI>
- <doc:GettingStartedWithUIKit>

### Modeling state

- ``ScreenState``
- ``ScreenStateStore``

### Navigation context

- <doc:TrackingOpenSource>
- ``ScreenOpenSource``

### SwiftUI

- ``ScreenStateView``
- ``ScreenStateDefaultEmptyView``
- ``ScreenStateDefaultLoadingView``
- ``ScreenStateDefaultErrorView``

### UIKit

- ``ScreenStateContainerView``
- ``ScreenStateDefaultEmptyUIView``
- ``ScreenStateDefaultLoadingUIView``
- ``ScreenStateDefaultErrorUIView``
