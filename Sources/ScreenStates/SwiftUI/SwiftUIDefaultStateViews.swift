#if canImport(SwiftUI)
import SwiftUI

/// Default placeholder sizing — smaller on watchOS's compact screens,
/// where a 56pt icon (sized right for iOS/macOS/tvOS/visionOS) would
/// dominate the whole display.
private enum ScreenStatesMetrics {
    #if os(watchOS)
    static let iconSize: CGFloat = 28
    static let spinnerSize: CGFloat = 24
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

    public init() {}

    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(
                AngularGradient(colors: [.pink, .orange, .yellow, .pink], center: .center),
                style: StrokeStyle(lineWidth: ScreenStatesMetrics.spinnerLineWidth, lineCap: .round)
            )
            .frame(width: ScreenStatesMetrics.spinnerSize, height: ScreenStatesMetrics.spinnerSize)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
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

    public init(title: String = .screenStatesNothingHere, systemImage: String = "tray.fill") {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .font(.system(size: ScreenStatesMetrics.iconSize))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .accessibilityIdentifier("screenStates.empty")
        .onAppear {
            AccessibilityNotification.Announcement(title).post()
        }
    }
}

/// Default placeholder shown when a screen's data failed to load, with an
/// optional retry action.
public struct ScreenStateDefaultErrorView: View {
    private let error: Error
    private let onRetry: (() -> Void)?
    #if os(tvOS)
    @Namespace private var focusNamespace
    #endif

    public init(error: Error, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text(String.screenStatesSomethingWentWrong)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: ScreenStatesMetrics.iconSize))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        } description: {
            Text(error.localizedDescription)
        } actions: {
            if let onRetry {
                Button(String.screenStatesRetry, action: onRetry)
                    .accessibilityIdentifier("screenStates.error.retryButton")
                    #if os(tvOS)
                    .prefersDefaultFocus(true, in: focusNamespace)
                    #endif
            }
        }
        .accessibilityIdentifier("screenStates.error")
        .onAppear {
            AccessibilityNotification.Announcement("\(String.screenStatesSomethingWentWrong). \(error.localizedDescription)").post()
        }
        #if os(tvOS)
        .focusScope(focusNamespace)
        #endif
    }
}
#endif
