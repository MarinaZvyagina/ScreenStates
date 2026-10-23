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
    static let compactIconSize: CGFloat = 16
    static let spinnerSize: CGFloat = 24
    static let compactSpinnerSize: CGFloat = 14
    static let spinnerLineWidth: CGFloat = 3
    #elseif targetEnvironment(macCatalyst)
    static let iconSize: CGFloat = 48
    static let compactIconSize: CGFloat = 24
    static let spinnerSize: CGFloat = 36
    static let compactSpinnerSize: CGFloat = 20
    static let spinnerLineWidth: CGFloat = 3
    #else
    static let iconSize: CGFloat = 56
    static let compactIconSize: CGFloat = 28
    static let spinnerSize: CGFloat = 44
    static let compactSpinnerSize: CGFloat = 24
    static let spinnerLineWidth: CGFloat = 4
    #endif

    static func iconSize(for style: ScreenStatePlaceholderStyle) -> CGFloat {
        style == .compact ? compactIconSize : iconSize
    }

    static func spinnerSize(for style: ScreenStatePlaceholderStyle) -> CGFloat {
        style == .compact ? compactSpinnerSize : spinnerSize
    }
}

/// Default placeholder shown while a screen's data is loading.
public struct ScreenStateDefaultLoadingView: View {
    private let style: ScreenStatePlaceholderStyle
    @State private var isRotating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.screenStatesTheme) private var theme

    public init(style: ScreenStatePlaceholderStyle = .standard) {
        self.style = style
    }

    private var strokeStyle: AnyShapeStyle {
        if colorSchemeContrast == .increased {
            return AnyShapeStyle(Color.primary)
        }
        if let tint = theme.tint {
            return AnyShapeStyle(tint)
        }
        return AnyShapeStyle(AngularGradient(colors: [.pink, .orange, .yellow, .pink], center: .center))
    }

    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(
                strokeStyle,
                style: StrokeStyle(lineWidth: ScreenStatesMetrics.spinnerLineWidth, lineCap: .round)
            )
            .frame(width: ScreenStatesMetrics.spinnerSize(for: style), height: ScreenStatesMetrics.spinnerSize(for: style))
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(reduceMotion ? nil : .linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
            .onAppear {
                isRotating = true
                AccessibilityNotification.Announcement(String.screenStatesLoading).post()
            }
            // `.standard` fills the screen it's presumed to own; `.compact`
            // sizes to the ring alone, so it doesn't force a card/section
            // open to the full available space just to host a spinner.
            .frame(
                maxWidth: style == .standard ? .infinity : nil,
                maxHeight: style == .standard ? .infinity : nil
            )
            .accessibilityLabel(String.screenStatesLoading)
            .accessibilityIdentifier("screenStates.loading")
    }
}

/// Default placeholder shown when a screen has no data to display.
public struct ScreenStateDefaultEmptyView: View {
    private let title: String
    private let systemImage: String
    private let style: ScreenStatePlaceholderStyle
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.screenStatesTheme) private var theme
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    public init(
        title: String = .screenStatesNothingHere,
        systemImage: String = "tray.fill",
        style: ScreenStatePlaceholderStyle = .standard
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
    }

    public var body: some View {
        // `ContentUnavailableView` has no configuration point for either a
        // horizontal arrangement or a card-sized footprint, so both the
        // compact-height (landscape iPhone) layout and the `.compact` style
        // build their own layout directly instead of going through it. A
        // compact-height layout — where stacking the icon above the title
        // the way the portrait-sized column always assumed leaves too
        // little height to fit both without clipping at large Dynamic Type
        // sizes — mirrors ``ScreenStateDefaultEmptyUIView``'s `UIStackView`
        // axis switch. `.compact` style takes priority: a card/section's
        // size is dictated by the card, not the device's orientation.
        Group {
            if style == .compact {
                compactStyleContent
            } else if isCompactHeight {
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

    private func icon(size: CGFloat) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: size))
            .foregroundStyle(fillStyle)
    }

    private var fillStyle: AnyShapeStyle {
        if colorSchemeContrast == .increased {
            return AnyShapeStyle(Color.primary)
        }
        if let tint = theme.tint {
            return AnyShapeStyle(tint)
        }
        return AnyShapeStyle(LinearGradient(colors: [.pink, .orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var content: some View {
        ContentUnavailableView {
            Label {
                Text(title).font(theme.titleFont)
            } icon: {
                icon(size: ScreenStatesMetrics.iconSize)
            }
        }
    }

    private var compactContent: some View {
        HStack(spacing: 16) {
            icon(size: ScreenStatesMetrics.iconSize)
            Text(title)
                .font(theme.titleFont ?? .headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Sized to fit inside a card or section instead of a whole screen —
    /// no `.frame(maxWidth:maxHeight:)` forcing it to expand, and a smaller
    /// icon/font throughout.
    private var compactStyleContent: some View {
        VStack(spacing: 8) {
            icon(size: ScreenStatesMetrics.iconSize(for: .compact))
            Text(title)
                .font(theme.titleFont ?? .footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
}

/// Default placeholder shown when a screen's data failed to load, with an
/// optional retry action.
public struct ScreenStateDefaultErrorView: View {
    private let error: Error
    private let onRetry: (() -> Void)?
    private let secondaryAction: (title: String, action: () -> Void)?
    private let style: ScreenStatePlaceholderStyle
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.screenStatesTheme) private var theme
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    #if os(tvOS)
    @Namespace private var focusNamespace
    #endif

    /// - Parameters:
    ///   - error: the error to describe.
    ///   - onRetry: an optional retry action; shows a Retry button when given.
    ///   - secondaryAction: an optional second button shown alongside
    ///     Retry — e.g. `(title: "Go Back", action: goBack)`. Hidden by
    ///     default, so existing call sites are unaffected.
    ///   - style: the placeholder's visual style.
    public init(
        error: Error,
        onRetry: (() -> Void)? = nil,
        secondaryAction: (title: String, action: () -> Void)? = nil,
        style: ScreenStatePlaceholderStyle = .standard
    ) {
        self.error = error
        self.onRetry = onRetry
        self.secondaryAction = secondaryAction
        self.style = style
    }

    public var body: some View {
        // `ContentUnavailableView` has no configuration point for either a
        // horizontal arrangement or a card-sized footprint, so both the
        // compact-height (landscape iPhone) layout and the `.compact` style
        // build their own layout directly instead of going through it. A
        // compact-height layout — where stacking the icon above the
        // message/Retry column the way the portrait-sized column always
        // assumed leaves too little height to fit both without clipping at
        // large Dynamic Type sizes — mirrors
        // ``ScreenStateDefaultErrorUIView``'s `UIStackView` axis switch.
        // `.compact` style takes priority: a card/section's size is
        // dictated by the card, not the device's orientation. tvOS is
        // always `.regular`, so neither branch affects the focus-engine
        // path below.
        Group {
            if style == .compact {
                compactStyleContent
            } else if isCompactHeight {
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

    /// `true` for a `URLError` indicating no connectivity or a timed-out
    /// request — see ``ScreenState/isConnectivityError(_:)``.
    private var isConnectivityError: Bool {
        ScreenState<Never>.isConnectivityError(error)
    }

    private var titleText: String {
        isConnectivityError ? .screenStatesConnectionIssue : .screenStatesSomethingWentWrong
    }

    /// `error`'s ``ScreenStateDisplayableError/displayMessage`` when it
    /// conforms to that protocol, otherwise `localizedDescription` — see
    /// ``ScreenState/displayMessage(for:)``.
    private var displayMessage: String {
        ScreenState<Never>.displayMessage(for: error)
    }

    private func icon(size: CGFloat) -> some View {
        Image(systemName: isConnectivityError ? "wifi.exclamationmark" : "exclamationmark.triangle.fill")
            .font(.system(size: size))
            .foregroundStyle(fillStyle)
    }

    private var fillStyle: AnyShapeStyle {
        if colorSchemeContrast == .increased {
            return AnyShapeStyle(Color.primary)
        }
        if let tint = theme.tint {
            return AnyShapeStyle(tint)
        }
        return AnyShapeStyle(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    // swift-format-ignore
    // The #if/#endif here wrap a single modifier mid-chain, not a whole
    // statement — swift-format's indentConditionalCompilationBlocks: false
    // (set repo-wide so file-scope `#if canImport(...)` wrappers don't get
    // needlessly indented) misapplies to this case too and would de-indent
    // `.hoverEffect` out of alignment with the rest of the chain.
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

    private func secondaryActionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .accessibilityIdentifier("screenStates.error.secondaryActionButton")
    }

    // swift-format-ignore
    // Same reason as retryButton(onRetry:) above: the #if/#endif inside
    // `actions:` wrap a single modifier mid-chain.
    private var content: some View {
        ContentUnavailableView {
            Label {
                Text(titleText).font(theme.titleFont)
            } icon: {
                icon(size: ScreenStatesMetrics.iconSize)
            }
        } description: {
            Text(displayMessage).font(theme.messageFont)
        } actions: {
            if let onRetry {
                retryButton(onRetry: onRetry)
                    #if os(tvOS)
                    .prefersDefaultFocus(true, in: focusNamespace)
                    #endif
            }
            if let secondaryAction {
                secondaryActionButton(title: secondaryAction.title, action: secondaryAction.action)
                    #if os(tvOS)
                    // Only the primary action should pull default focus;
                    // skip this when Retry is also shown, so the two don't
                    // fight over it.
                    .prefersDefaultFocus(onRetry == nil, in: focusNamespace)
                    #endif
            }
        }
    }

    private var compactContent: some View {
        HStack(alignment: .center, spacing: 16) {
            icon(size: ScreenStatesMetrics.iconSize)
            VStack(alignment: .leading, spacing: 12) {
                Text(displayMessage)
                    .font(theme.messageFont ?? .subheadline)
                    .foregroundStyle(.secondary)
                if let onRetry {
                    retryButton(onRetry: onRetry)
                }
                if let secondaryAction {
                    secondaryActionButton(title: secondaryAction.title, action: secondaryAction.action)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Sized to fit inside a card or section instead of a whole screen —
    /// no `.frame(maxWidth:maxHeight:)` forcing it to expand, and a smaller
    /// icon/font throughout.
    private var compactStyleContent: some View {
        HStack(alignment: .center, spacing: 12) {
            icon(size: ScreenStatesMetrics.iconSize(for: .compact))
            VStack(alignment: .leading, spacing: 6) {
                Text(displayMessage)
                    .font(theme.messageFont ?? .footnote)
                    .foregroundStyle(.secondary)
                if let onRetry {
                    retryButton(onRetry: onRetry)
                        .font(theme.messageFont ?? .footnote)
                }
                if let secondaryAction {
                    secondaryActionButton(title: secondaryAction.title, action: secondaryAction.action)
                        .font(theme.messageFont ?? .footnote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
    }
}
#endif
