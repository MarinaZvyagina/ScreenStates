/// Lets an error type supply its own user-facing message, distinct from
/// `localizedDescription` — which is often a debugging string (or, for a
/// plain `Error` with no `CustomStringConvertible`/`LocalizedError`
/// conformance, just the type name) rather than something to put in front
/// of the person using the app.
///
/// ```swift
/// struct APIError: ScreenStateDisplayableError {
///     let displayMessage: String
/// }
///
/// store.setError(APIError(displayMessage: "That article was removed."))
/// ```
///
/// ``ScreenState/displayMessage(for:)`` checks for this conformance and
/// falls back to `localizedDescription` for every other error — adopt it on
/// your own error types and the default Error placeholders pick it up with
/// no call-site changes.
public protocol ScreenStateDisplayableError: Error {
    /// The message to show the person using the app.
    var displayMessage: String { get }
}
