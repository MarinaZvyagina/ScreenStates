#if canImport(SwiftUI)
import SwiftUI

/// An alternative Loading placeholder: a pulsing skeleton of a circular
/// avatar plus two text-line placeholders, instead of a spinner. Opt-in —
/// ``ScreenStateDefaultLoadingView`` is still what every default-wired
/// `ScreenStateView`/`ScreenStateContainerView`/`ScreenStateViewController`
/// shows; pass this one explicitly wherever a `loadingView`-shaped
/// placeholder is expected.
public struct ScreenStateShimmerLoadingView: View {
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(fillStyle)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(fillStyle)
                    .frame(width: 160, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(fillStyle)
                    .frame(width: 100, height: 14)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(isPulsing ? 1 : 0.4)
        .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
        .onAppear {
            isPulsing = true
            AccessibilityNotification.Announcement(String.screenStatesLoading).post()
        }
        .accessibilityLabel(String.screenStatesLoading)
        .accessibilityIdentifier("screenStates.shimmerLoading")
    }

    private var fillStyle: Color {
        colorSchemeContrast == .increased ? .secondary.opacity(0.6) : .secondary.opacity(0.3)
    }
}
#endif
