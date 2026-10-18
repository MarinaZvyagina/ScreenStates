#if canImport(SwiftUI)
import SwiftUI

/// An alternative Loading placeholder that mirrors the shape of the real
/// content, instead of a generic spinner or skeleton: render what the
/// content would look like once loaded, and this redacts it via SwiftUI's
/// `.redacted(reason: .placeholder)` — the same system-provided graying/
/// blurring every other redacted view uses. Opt-in — pass your real
/// content's view wherever a `loadingView`-shaped placeholder is expected.
///
/// No UIKit equivalent: `redacted(reason:)` is a SwiftUI-only modifier,
/// with nothing comparable in UIKit to build an equivalent on top of.
///
/// ```swift
/// ScreenStateRedactedLoadingView {
///     ArticleRow(article: .placeholder)
/// }
/// ```
public struct ScreenStateRedactedLoadingView<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .redacted(reason: .placeholder)
            .accessibilityLabel(String.screenStatesLoading)
            .accessibilityIdentifier("screenStates.redactedLoading")
            .onAppear {
                AccessibilityNotification.Announcement(String.screenStatesLoading).post()
            }
    }
}
#endif
