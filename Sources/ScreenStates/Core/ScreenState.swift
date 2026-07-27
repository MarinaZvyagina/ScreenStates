import Foundation
import Observation

/// The four canonical states of a screen: nothing to show yet, in flight,
/// showing data, or failed.
public enum ScreenState<Value> {
    case empty
    case loading
    case data(Value)
    case error(Error)
}

extension ScreenState {
    /// The wrapped value if the state is `.data`, otherwise `nil`.
    public var value: Value? {
        if case .data(let value) = self { value } else { nil }
    }

    /// The wrapped error if the state is `.error`, otherwise `nil`.
    public var error: Error? {
        if case .error(let error) = self { error } else { nil }
    }

    /// `true` while the state is `.loading`.
    public var isLoading: Bool {
        if case .loading = self { true } else { false }
    }

    /// `true` while the state is `.empty`.
    public var isEmpty: Bool {
        if case .empty = self { true } else { false }
    }
}

extension ScreenState: Equatable where Value: Equatable {
    public static func == (lhs: ScreenState<Value>, rhs: ScreenState<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty), (.loading, .loading):
            true
        case let (.data(lhsValue), .data(rhsValue)):
            lhsValue == rhsValue
        case let (.error(lhsError), .error(rhsError)):
            (lhsError as NSError) == (rhsError as NSError)
        default:
            false
        }
    }
}

extension ScreenState: Sendable where Value: Sendable {}

/// An `@Observable` holder of a screen's ``ScreenState``, driving both
/// SwiftUI and UIKit consumers from a single source of truth.
///
/// ```swift
/// let store = ScreenStateStore<[Article]>()
/// await store.load { try await api.fetchArticles() }
/// ```
@MainActor
@Observable
public final class ScreenStateStore<Value> {
    public private(set) var state: ScreenState<Value>

    public init(_ initial: ScreenState<Value> = .loading) {
        state = initial
    }

    public func setLoading() {
        state = .loading
    }

    public func setEmpty() {
        state = .empty
    }

    public func setData(_ value: Value) {
        state = .data(value)
    }

    public func setError(_ error: Error) {
        state = .error(error)
    }

    /// Runs `operation`, showing `.loading` while it's in flight and
    /// mapping its outcome to `.data` or `.error`.
    public func load(_ operation: @Sendable () async throws -> Value) async {
        setLoading()
        do {
            setData(try await operation())
        } catch {
            setError(error)
        }
    }
}

extension ScreenStateStore where Value: Collection {
    /// Like ``load(_:)``, but maps an empty result to `.empty` instead of
    /// `.data` — convenient when `Value` is a list of items to display.
    public func loadCollection(_ operation: @Sendable () async throws -> Value) async {
        setLoading()
        do {
            let result = try await operation()
            state = result.isEmpty ? .empty : .data(result)
        } catch {
            setError(error)
        }
    }
}
