#if canImport(SwiftUI)
import SwiftUI

/// Default placeholder sizing — smaller on watchOS's compact screens,
/// where a 56pt icon (sized right for iOS/macOS/tvOS/visionOS) would
/// dominate the whole display, and a bit smaller still on Mac Catalyst,
/// where a window is driven by a precise pointer rather than a touch
/// target that needs to stay comfortably tappable.
private enum ScreenStatesMetrics {
    #if os(watchOS)
    static let iconSize: CGFloat = 28
    static let spinnerSize: CGFloat = 24
    static let spinnerLineWidth: CGFloat = 3
    #elseif targetEnvironment(macCatalyst)
    static let iconSize: CGFloat = 48
    static let spinnerSize: CGFloat = 36
    static let spinnerLineWidth: CGFloat = 3
    #else
    static let iconSize: CGFloat = 56
    static let spinnerSize: CGFloat = 44
    static let spinnerLineWidth: CGFloat = 4
    #endif
}

/// Default placeholder shown while a screen's data is loading.
public struct ScreenStateDefaultLoadingView: View {
    @State private var isRotating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init() {}

    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(
                colorSchemeContrast == .increased
                    ? AnyShapeStyle(Color.primary)
                    : AnyShapeStyle(AngularGradient(colors: [.pink, .orange, .yellow, .pink], center: .center)),
                style: StrokeStyle(lineWidth: ScreenStatesMetrics.spinnerLineWidth, lineCap: .round)
            )
            .frame(width: ScreenStatesMetrics.spinnerSize, height: ScreenStatesMetrics.spinnerSize)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(reduceMotion ? nil : .linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
            .onAppear {
                isRotating = true
                AccessibilityNotification.Announcement(String.screenStatesLoading).post()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(String.screenStatesLoading)
            .accessibilityIdentifier("screenStates.loading")
    }
}

/// Default placeholder shown when a screen has no data to display.
public struct ScreenStateDefaultEmptyView: View {
    private let title: String
    private let systemImage: String
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    public init(title: String = .screenStatesNothingHere, systemImage: String = "tray.fill") {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        // `ContentUnavailableView` has no configuration point for a
        // horizontal arrangement, so a compact-height (landscape iPhone)
        // layout — where stacking the icon above the title the way the
        // portrait-sized column always assumed leaves too little height to
        // fit both without clipping at large Dynamic Type sizes — builds
        // its own layout directly instead of going through it, mirroring
        // ``ScreenStateDefaultEmptyUIView``'s `UIStackView` axis switch.
        Group {
            if isCompactHeight {
                compactContent
            } else {
                content
            }
        }
        .accessibilityIdentifier("screenStates.empty")
        .onAppear {
            AccessibilityNotification.Announcement(title).post()
        }
    }

    private var isCompactHeight: Bool {
        #if os(iOS)
        verticalSizeClass == .compact
        #else
        false
        #endif
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.system(size: ScreenStatesMetrics.iconSize))
            .foregroundStyle(
                colorSchemeContrast == .increased
                    ? AnyShapeStyle(Color.primary)
                    : AnyShapeStyle(LinearGradient(
                        colors: [.pink, .orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
    }

    private var content: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                icon
            }
        }
    }

    private var compactContent: some View {
        HStack(spacing: 16) {
            icon
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Default placeholder shown when a screen's data failed to load, with an
/// optional retry action.
public struct ScreenStateDefaultErrorView: View {
    private let error: Error
    private let onRetry: (() -> Void)?
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    #if os(tvOS)
    @Namespace private var focusNamespace
    #endif

    public init(error: Error, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    public var body: some View {
        // `ContentUnavailableView` has no configuration point for a
        // horizontal arrangement, so a compact-height (landscape iPhone)
        // layout — where stacking the icon above the message/Retry column
        // the way the portrait-sized column always assumed leaves too
        // little height to fit both without clipping at large Dynamic Type
        // sizes — builds its own layout directly instead of going through
        // it, mirroring ``ScreenStateDefaultErrorUIView``'s `UIStackView`
        // axis switch. tvOS is always `.regular`, so this never affects
        // the focus-engine path below.
        Group {
            if isCompactHeight {
                compactContent
            } else {
                content
            }
        }
        .accessibilityIdentifier("screenStates.error")
        .onAppear {
            AccessibilityNotification.Announcement(ScreenState<Never>.error(error).accessibilityAnnouncement ?? "").post()
        }
        #if os(tvOS)
        .focusScope(focusNamespace)
        #endif
    }

    private var isCompactHeight: Bool {
        #if os(iOS)
        verticalSizeClass == .compact
        #else
        false
        #endif
    }

    private var icon: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: ScreenStatesMetrics.iconSize))
            .foregroundStyle(
                colorSchemeContrast == .increased
                    ? AnyShapeStyle(Color.primary)
                    : AnyShapeStyle(LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
    }

    private func retryButton(onRetry: @escaping () -> Void) -> some View {
        Button(String.screenStatesRetry, action: onRetry)
            .accessibilityIdentifier("screenStates.error.retryButton")
            #if os(iOS) || os(visionOS)
            // A no-op without a pointer (plain touch on iPhone/iPad); shows
            // a deliberate hover highlight under Mac Catalyst or a
            // trackpad-equipped iPad instead of leaving it to whatever
            // `.automatic` happens to resolve to. Not available on macOS
            // or watchOS.
            .hoverEffect(.highlight)
            #endif
    }

    private var content: some View {
        ContentUnavailableView {
            Label {
                Text(String.screenStatesSomethingWentWrong)
            } icon: {
                icon
            }
        } description: {
            Text(error.localizedDescription)
        } actions: {
            if let onRetry {
                retryButton(onRetry: onRetry)
                    #if os(tvOS)
                    .prefersDefaultFocus(true, in: focusNamespace)
                    #endif
            }
        }
    }

    private var compactContent: some View {
        HStack(alignment: .center, spacing: 16) {
            icon
            VStack(alignment: .leading, spacing: 12) {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let onRetry {
                    retryButton(onRetry: onRetry)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
