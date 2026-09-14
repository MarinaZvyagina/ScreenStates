import Foundation

/// Localized text for the default placeholder views, resolved from this
/// package's own `Resources/Localizable.xcstrings` (via `Bundle.module`)
/// rather than the consuming app's bundle, so a custom `title` an app
/// passes in is never run back through localization. Public only because
/// they're used as default argument values in public initializers.
extension String {
    /// Announced to VoiceOver and shown as the accessibility label while a
    /// screen's data is loading.
    public static var screenStatesLoading: String {
        String(localized: "Loading", bundle: .module, comment: "Announced to VoiceOver and shown as the accessibility label while a screen's data is loading.")
    }

    /// Default title shown when a screen has no data to display.
    public static var screenStatesNothingHere: String {
        String(localized: "Nothing Here", bundle: .module, comment: "Default title shown when a screen has no data to display.")
    }

    /// Default title shown when a screen's data failed to load.
    public static var screenStatesSomethingWentWrong: String {
        String(localized: "Something Went Wrong", bundle: .module, comment: "Default title shown when a screen's data failed to load.")
    }

    /// Title of the button that retries loading after an error.
    public static var screenStatesRetry: String {
        String(localized: "Retry", bundle: .module, comment: "Title of the button that retries loading after an error.")
    }
}
