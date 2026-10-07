# Accessibility

Everything the default placeholders — and your own custom ones — get for free: VoiceOver, Reduce Motion, Increase Contrast, Dynamic Type, and stable identifiers for XCUITest.

## Overview

A placeholder is often the *only* thing on screen for a few hundred milliseconds, or the only thing a user with a slow connection sees for much longer than that — so it's worth it being as accessible as the real content it stands in for. The default `ScreenStateDefault{Empty,Loading,Error}View`/`UIView`s handle all of this out of the box; this article rounds up what they do and how a fully custom placeholder can match them.

## VoiceOver announcements

Each default placeholder announces its own appearance — `AccessibilityNotification.Announcement(_:).post()` in SwiftUI, `UIAccessibility.post(notification:.announcement, argument:)` in UIKit — so a screen settling into `.empty`, `.loading`, or `.error` is heard, not just seen.

``ScreenState/accessibilityAnnouncement`` exposes that same wording for any case, so a fully custom placeholder can announce transitions consistently instead of inventing its own text:

```swift
.onAppear {
    if let announcement = state.accessibilityAnnouncement {
        AccessibilityNotification.Announcement(announcement).post()
    }
}
```

It's `nil` for `.data` — your own content is what VoiceOver should read at that point — and, for `.empty`, it's the default "Nothing Here" text; announce your own custom title directly instead if your placeholder shows one, so VoiceOver matches what's on screen. See <doc:GettingStartedWithSwiftUI> and <doc:GettingStartedWithUIKit> for the full examples.

## Reduce Motion

The default Loading placeholder's ring spins via a repeating rotation animation — purely decorative, and exactly the kind of large, continuous motion Reduce Motion exists to suppress. `ScreenStateDefaultLoadingView` reads SwiftUI's `accessibilityReduceMotion` environment value; `ScreenStateDefaultLoadingUIView` reads `UIAccessibility.isReduceMotionEnabled` and also observes `UIAccessibility.reduceMotionStatusDidChangeNotification`, so an already-visible spinner responds immediately if the setting changes while on screen, not just on the next appearance. Either way, the ring stays static — still colorful, just not spinning — instead of disabling itself entirely, since a static ring still communicates "loading" on its own.

## Increase Contrast

All three default placeholders' gradient icons/ring respect Increase Contrast — SwiftUI's `colorSchemeContrast` environment value, UIKit's `UIAccessibility.isDarkerSystemColorsEnabled` (observed live the same way Reduce Motion is). A multi-stop gradient can dip below an acceptable contrast ratio in places a single flat color never does, so when Increase Contrast is on, every gradient is swapped for a solid `.label`/`.primary` tint instead.

## Dynamic Type

The default Empty/Error placeholders' text scales with Dynamic Type: SwiftUI's `ScreenStateDefaultEmptyView`/`ErrorView` get this for free from `ContentUnavailableView`'s own text styles, and `ScreenStateDefaultEmptyUIView`/`ErrorUIView`'s labels use `UIFont.preferredFont(forTextStyle: .body, compatibleWith:)`. Both are covered up to the largest accessibility size by snapshot tests, so a regression that silently pins the text to a fixed size would be caught. The default Loading placeholder has no text at all — its ring is a fixed-size shape, unaffected by Dynamic Type by design.

## Identifiers for XCUITest

Every default placeholder exposes a stable `accessibilityIdentifier`, independent of any localized or custom text, so a UI test can assert which state is showing without string-matching:

| Identifier | Shown on |
|---|---|
| `screenStates.loading` | ``ScreenStateDefaultLoadingView``/``ScreenStateDefaultLoadingUIView`` |
| `screenStates.empty` | ``ScreenStateDefaultEmptyView``/``ScreenStateDefaultEmptyUIView`` |
| `screenStates.error` | ``ScreenStateDefaultErrorView``/``ScreenStateDefaultErrorUIView`` |
| `screenStates.error.retryButton` | The Retry button, when `onRetry` is given |

## See Also

- ``ScreenState``
- <doc:GettingStartedWithSwiftUI>
- <doc:GettingStartedWithUIKit>
