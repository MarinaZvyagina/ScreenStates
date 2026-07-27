#if canImport(SwiftUI)
import SwiftUI

/// Default placeholder shown while a screen's data is loading.
public struct ScreenStateDefaultLoadingView: View {
    public init() {}

    public var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Default placeholder shown when a screen has no data to display.
public struct ScreenStateDefaultEmptyView: View {
    private let title: String
    private let systemImage: String

    public init(title: String = "Nothing Here", systemImage: String = "tray") {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        ContentUnavailableView(title, systemImage: systemImage)
    }
}

/// Default placeholder shown when a screen's data failed to load, with an
/// optional retry action.
public struct ScreenStateDefaultErrorView: View {
    private let error: Error
    private let onRetry: (() -> Void)?

    public init(error: Error, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    public var body: some View {
        ContentUnavailableView {
            Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            if let onRetry {
                Button("Retry", action: onRetry)
            }
        }
    }
}
#endif
