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

    /// `true` while ``refresh(_:)`` or ``refreshCollection(_:)`` is fetching
    /// in the background with the previous data still shown in `state`.
    public private(set) var isRefreshing = false

    /// The error from the most recently failed ``refresh(_:)`` or
    /// ``refreshCollection(_:)``. `state` is left untouched by a refresh
    /// failure — the last good data stays on screen — so this is the only
    /// way to learn a background refresh failed. Cleared at the start of the
    /// next load or refresh.
    public private(set) var refreshError: Error?

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
        refreshError = nil
        setLoading()
        do {
            setData(try await operation())
        } catch {
            setError(error)
        }
    }

    /// Like ``load(_:)``, but keeps any data already in `state` on screen
    /// while `operation` runs instead of switching to `.loading` — the
    /// pattern behind pull-to-refresh, where the list shouldn't disappear
    /// while it's being refetched. ``isRefreshing`` is `true` for the
    /// duration. On success `state` is replaced as usual; on failure `state`
    /// is left alone and the error is reported via ``refreshError`` instead.
    ///
    /// Falls back to ``load(_:)`` when there's no data yet to preserve.
    public func refresh(_ operation: @Sendable () async throws -> Value) async {
        guard state.value != nil else {
            await load(operation)
            return
        }
        refreshError = nil
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            setData(try await operation())
        } catch {
            refreshError = error
        }
    }
}

extension ScreenStateStore where Value: Collection {
    /// Like ``load(_:)``, but maps an empty result to `.empty` instead of
    /// `.data` — convenient when `Value` is a list of items to display.
    public func loadCollection(_ operation: @Sendable () async throws -> Value) async {
        refreshError = nil
        setLoading()
        do {
            let result = try await operation()
            state = result.isEmpty ? .empty : .data(result)
        } catch {
            setError(error)
        }
    }

    /// Like ``refresh(_:)``, but maps an empty result to `.empty` instead of
    /// `.data`, matching ``loadCollection(_:)``.
    public func refreshCollection(_ operation: @Sendable () async throws -> Value) async {
        guard state.value != nil else {
            await loadCollection(operation)
            return
        }
        refreshError = nil
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let result = try await operation()
            state = result.isEmpty ? .empty : .data(result)
        } catch {
            refreshError = error
        }
    }
}
