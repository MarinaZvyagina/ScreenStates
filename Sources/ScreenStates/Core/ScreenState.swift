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

    /// The same text the default placeholders announce to VoiceOver for
    /// this case, reusable by a fully custom placeholder that wants to
    /// announce transitions with the same wording instead of inventing its
    /// own. `nil` for `.data`, since at that point a custom placeholder's
    /// own content is what VoiceOver should read, not a transition
    /// announcement.
    ///
    /// For `.empty`, this is the default "Nothing Here" title — if your
    /// placeholder shows its own custom title instead (as
    /// ``ScreenStateDefaultEmptyView``'s `title` parameter allows), announce
    /// that title directly rather than this property, so VoiceOver matches
    /// what's actually on screen.
    public var accessibilityAnnouncement: String? {
        switch self {
        case .empty: .screenStatesNothingHere
        case .loading: .screenStatesLoading
        case .data: nil
        case .error(let error): "\(String.screenStatesSomethingWentWrong). \(error.localizedDescription)"
        }
    }

    /// Transforms the wrapped value with `transform` if the state is
    /// `.data`, leaving every other case untouched — the `.data` case of
    /// `Optional.map`.
    ///
    /// ```swift
    /// let titles: ScreenState<[String]> = state.map { articles in articles.map(\.title) }
    /// ```
    public func map<NewValue>(_ transform: (Value) -> NewValue) -> ScreenState<NewValue> {
        switch self {
        case .empty: .empty
        case .loading: .loading
        case .data(let value): .data(transform(value))
        case .error(let error): .error(error)
        }
    }

    /// Transforms the wrapped value into a whole new `ScreenState` with
    /// `transform` if the state is `.data`, leaving every other case
    /// untouched — the `.data` case of `Optional.flatMap`, useful when the
    /// transform itself might produce `.empty` (e.g. after filtering a
    /// collection down to nothing).
    ///
    /// ```swift
    /// let filtered: ScreenState<[Article]> = state.flatMap { articles in
    ///     let unread = articles.filter { !$0.isRead }
    ///     return unread.isEmpty ? .empty : .data(unread)
    /// }
    /// ```
    public func flatMap<NewValue>(_ transform: (Value) -> ScreenState<NewValue>) -> ScreenState<NewValue> {
        switch self {
        case .empty: .empty
        case .loading: .loading
        case .data(let value): transform(value)
        case .error(let error): .error(error)
        }
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
///
/// If a second `load`/`refresh`/`loadWithRetry` call starts before an
/// earlier one has finished, only the most recently started call's result is
/// ever applied — an earlier, now-stale response landing late can't
/// overwrite state a newer call already produced. Call ``cancel()`` to stop
/// whichever one is currently running without waiting for it to resolve.
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

    /// Bumped by every `load`/`refresh`/`loadWithRetry` call; a call whose
    /// token no longer matches once its operation resolves knows a newer
    /// call has since started, and drops its own result instead of applying
    /// it.
    private var generation = 0

    /// The `Task` currently running a `load`/`loadCollection`/`refresh`/
    /// `refreshCollection`/`loadWithRetry` call, if any; what ``cancel()``
    /// cancels. `nonisolated(unsafe)` so `deinit` (always non-isolated) can
    /// cancel it too — safe since `Task` is `Sendable` and `Task.cancel()`
    /// can be called from any context. `@ObservationIgnored` since it's
    /// bookkeeping, not anything a view should re-render on.
    @ObservationIgnored
    private nonisolated(unsafe) var currentTask: Task<Void, Never>?

    public init(_ initial: ScreenState<Value> = .loading) {
        state = initial
    }

    /// Cancels `currentTask` as a last-resort safety net, mirroring
    /// ``cancel()``, in case something is ever still tracked here by the
    /// time the store itself is deallocated. In practice `load`/`refresh`/
    /// etc. already await their own task to completion before returning, so
    /// `currentTask` is normally already finished by the time `deinit` runs
    /// — this guards against that assumption changing later, for free.
    deinit {
        currentTask?.cancel()
    }

    private func beginOperation() -> Int {
        generation += 1
        return generation
    }

    private func isCurrent(_ token: Int) -> Bool {
        token == generation
    }

    /// Cancels whatever `load`/`loadCollection`/`refresh`/
    /// `refreshCollection`/`loadWithRetry` call is currently in flight, if
    /// any. `state` (and `isRefreshing`/`refreshError`) are left exactly as
    /// they were — cancelling never surfaces a `CancellationError` through
    /// `state`, unlike letting `operation` itself fail.
    public func cancel() {
        currentTask?.cancel()
    }

    /// Snaps the store back to `state` (`.loading` by default), outside of
    /// a `load`/`refresh` call — useful for a full sign-out/reset flow,
    /// where whatever the store was showing or fetching no longer applies.
    ///
    /// Cancels whatever operation is currently in flight (as ``cancel()``
    /// does) and clears `isRefreshing`/`refreshError`, so nothing stale can
    /// land and overwrite `state` after the reset.
    public func reset(to state: ScreenState<Value> = .loading) {
        _ = beginOperation()
        cancel()
        isRefreshing = false
        refreshError = nil
        self.state = state
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
    public func load(_ operation: @escaping @Sendable () async throws -> Value) async {
        let token = beginOperation()
        refreshError = nil
        setLoading()
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let value = try await operation()
                guard !Task.isCancelled, self.isCurrent(token) else { return }
                self.setData(value)
            } catch {
                guard !Task.isCancelled, self.isCurrent(token) else { return }
                self.setError(error)
            }
        }
        currentTask = task
        await task.value
    }

    /// Like ``load(_:)``, but keeps any data already in `state` on screen
    /// while `operation` runs instead of switching to `.loading` — the
    /// pattern behind pull-to-refresh, where the list shouldn't disappear
    /// while it's being refetched. ``isRefreshing`` is `true` for the
    /// duration. On success `state` is replaced as usual; on failure `state`
    /// is left alone and the error is reported via ``refreshError`` instead.
    ///
    /// Falls back to ``load(_:)`` when there's no data yet to preserve.
    public func refresh(_ operation: @escaping @Sendable () async throws -> Value) async {
        guard state.value != nil else {
            await load(operation)
            return
        }
        let token = beginOperation()
        refreshError = nil
        isRefreshing = true
        defer { if isCurrent(token) { isRefreshing = false } }
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let value = try await operation()
                guard !Task.isCancelled, self.isCurrent(token) else { return }
                self.setData(value)
            } catch {
                guard !Task.isCancelled, self.isCurrent(token) else { return }
                self.refreshError = error
            }
        }
        currentTask = task
        await task.value
    }

    /// Like ``load(_:)``, but retries a failing `operation` instead of
    /// settling into `.error` after the first failure. `state` stays
    /// `.loading` across every attempt; only the final failure (once
    /// `maxAttempts` is reached) or a success changes it.
    ///
    /// `backoff` is called with the attempt number that just failed (`1` for
    /// the first failure, `2` for the second, …) and returns how long to
    /// wait before trying again; the default doubles from one second.
    /// Cancelling via ``cancel()`` stops retrying and leaves `state`
    /// untouched, the same as every other call.
    public func loadWithRetry(
        maxAttempts: Int = 3,
        backoff: @escaping (Int) -> Duration = { attempt in .seconds(1 << (attempt - 1)) },
        _ operation: @escaping @Sendable () async throws -> Value
    ) async {
        let token = beginOperation()
        refreshError = nil
        setLoading()
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            var attempt = 1
            while true {
                do {
                    let value = try await operation()
                    guard !Task.isCancelled, self.isCurrent(token) else { return }
                    self.setData(value)
                    return
                } catch {
                    guard !Task.isCancelled, self.isCurrent(token) else { return }
                    guard attempt < maxAttempts else {
                        self.setError(error)
                        return
                    }
                    do {
                        try await Task.sleep(for: backoff(attempt))
                    } catch {
                        return // cancelled while waiting -- leave state as-is
                    }
                    guard !Task.isCancelled, self.isCurrent(token) else { return }
                    attempt += 1
                }
            }
        }
        currentTask = task
        await task.value
    }
}

extension ScreenStateStore where Value: Collection {
    /// Like ``load(_:)``, but maps an empty result to `.empty` instead of
    /// `.data` — convenient when `Value` is a list of items to display.
    public func loadCollection(_ operation: @escaping @Sendable () async throws -> Value) async {
        let token = beginOperation()
        refreshError = nil
        setLoading()
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await operation()
                guard !Task.isCancelled, self.isCurrent(token) else { return }
                self.state = result.isEmpty ? .empty : .data(result)
            } catch {
                guard !Task.isCancelled, self.isCurrent(token) else { return }
                self.setError(error)
            }
        }
        currentTask = task
        await task.value
    }

    /// Like ``refresh(_:)``, but maps an empty result to `.empty` instead of
    /// `.data`, matching ``loadCollection(_:)``.
    public func refreshCollection(_ operation: @escaping @Sendable () async throws -> Value) async {
        guard state.value != nil else {
            await loadCollection(operation)
            return
        }
        let token = beginOperation()
        refreshError = nil
        isRefreshing = true
        defer { if isCurrent(token) { isRefreshing = false } }
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await operation()
                guard !Task.isCancelled, self.isCurrent(token) else { return }
                self.state = result.isEmpty ? .empty : .data(result)
            } catch {
                guard !Task.isCancelled, self.isCurrent(token) else { return }
                self.refreshError = error
            }
        }
        currentTask = task
        await task.value
    }
}
