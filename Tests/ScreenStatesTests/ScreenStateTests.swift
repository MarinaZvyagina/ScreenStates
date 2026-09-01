import Foundation
import Testing
@testable import ScreenStates

@Suite("ScreenState")
struct ScreenStateTests {
    private struct SampleError: Error {}

    @Test("value is only non-nil for .data")
    func valueHelper() {
        #expect(ScreenState<Int>.data(42).value == 42)
        #expect(ScreenState<Int>.loading.value == nil)
    }

    @Test("error is only non-nil for .error")
    func errorHelper() {
        #expect(ScreenState<Int>.error(SampleError()).error != nil)
        #expect(ScreenState<Int>.empty.error == nil)
    }

    @Test("isLoading reflects state")
    func isLoadingHelper() {
        #expect(ScreenState<Int>.loading.isLoading)
        #expect(!ScreenState<Int>.empty.isLoading)
    }

    @Test("isEmpty reflects state")
    func isEmptyHelper() {
        #expect(ScreenState<Int>.empty.isEmpty)
        #expect(!ScreenState<Int>.loading.isEmpty)
    }

    @Test("Equatable compares by case and payload")
    func equatable() {
        #expect(ScreenState<Int>.data(1) == ScreenState<Int>.data(1))
        #expect(ScreenState<Int>.data(1) != ScreenState<Int>.data(2))
        #expect(ScreenState<Int>.empty == ScreenState<Int>.empty)
        #expect(ScreenState<Int>.loading != ScreenState<Int>.empty)
    }
}

@Suite("ScreenStateStore")
@MainActor
struct ScreenStateStoreTests {
    private struct SampleError: Error {}

    @Test("load(_:) success maps to .data")
    func loadSuccess() async {
        let store = ScreenStateStore<Int>()
        await store.load { 7 }
        #expect(store.state == .data(7))
    }

    @Test("load(_:) failure maps to .error")
    func loadFailure() async {
        let store = ScreenStateStore<Int>()
        await store.load { throw SampleError() }
        #expect(store.state.error is SampleError)
    }

    @Test("loadCollection(_:) maps an empty result to .empty")
    func loadCollectionEmpty() async {
        let store = ScreenStateStore<[Int]>()
        await store.loadCollection { [] }
        #expect(store.state.isEmpty)
    }

    @Test("loadCollection(_:) maps a non-empty result to .data")
    func loadCollectionNonEmpty() async {
        let store = ScreenStateStore<[Int]>()
        await store.loadCollection { [1, 2, 3] }
        #expect(store.state == .data([1, 2, 3]))
    }

    @Test("manual setters update state directly")
    func manualSetters() {
        let store = ScreenStateStore<Int>()

        store.setEmpty()
        #expect(store.state.isEmpty)

        store.setData(9)
        #expect(store.state.value == 9)

        store.setError(SampleError())
        #expect(store.state.error is SampleError)

        store.setLoading()
        #expect(store.state.isLoading)
    }

    @Test("refresh(_:) falls back to load(_:) when there's no data yet")
    func refreshWithNoExistingData() async {
        let store = ScreenStateStore<Int>()
        await store.refresh { 7 }
        #expect(store.state == .data(7))
        #expect(!store.isRefreshing)
    }

    @Test("refresh(_:) keeps existing data on screen and sets isRefreshing while in flight")
    func refreshKeepsDataWhileInFlight() async {
        let store = ScreenStateStore<Int>()
        store.setData(1)
        let gate = Gate()

        let task = Task {
            await store.refresh {
                await gate.waitForOpen()
                return 2
            }
        }

        await gate.waitForStart()
        #expect(store.state == .data(1))
        #expect(store.isRefreshing)

        await gate.open()
        await task.value

        #expect(store.state == .data(2))
        #expect(!store.isRefreshing)
    }

    @Test("refresh(_:) failure leaves old data in place and reports refreshError")
    func refreshFailureKeepsOldData() async {
        let store = ScreenStateStore<Int>()
        store.setData(1)

        await store.refresh { throw SampleError() }

        #expect(store.state == .data(1))
        #expect(store.refreshError is SampleError)
        #expect(!store.isRefreshing)
    }

    @Test("load(_:) clears a stale refreshError from a previous failed refresh")
    func loadClearsStaleRefreshError() async {
        let store = ScreenStateStore<Int>()
        store.setData(1)
        await store.refresh { throw SampleError() }
        #expect(store.refreshError != nil)

        await store.load { 2 }
        #expect(store.refreshError == nil)
    }

    @Test("refreshCollection(_:) maps a newly empty result to .empty")
    func refreshCollectionToEmpty() async {
        let store = ScreenStateStore<[Int]>()
        store.setData([1, 2, 3])

        await store.refreshCollection { [] }

        #expect(store.state.isEmpty)
        #expect(!store.isRefreshing)
    }
}

/// Lets a test observe a `ScreenStateStore` in the middle of an in-flight
/// async operation instead of only before/after it, by suspending the
/// operation until the test explicitly releases it.
private actor Gate {
    private var startContinuation: CheckedContinuation<Void, Never>?
    private var openContinuation: CheckedContinuation<Void, Never>?

    func waitForStart() async {
        await withCheckedContinuation { startContinuation = $0 }
    }

    func waitForOpen() async {
        startContinuation?.resume()
        startContinuation = nil
        await withCheckedContinuation { openContinuation = $0 }
    }

    func open() {
        openContinuation?.resume()
        openContinuation = nil
    }
}

@Suite("ScreenOpenSource")
struct ScreenOpenSourceTests {
    private enum AppScreen: Hashable {
        case home
        case settings
    }

    @Test("originatingScreen is set for push, pop, and presented")
    func originatingScreenForNavigationCases() {
        #expect(ScreenOpenSource.push(from: AppScreen.home).originatingScreen == .home)
        #expect(ScreenOpenSource.pop(from: AppScreen.settings).originatingScreen == .settings)
        #expect(ScreenOpenSource.presented(from: AppScreen.home).originatingScreen == .home)
    }

    @Test("originatingScreen is nil for deep link, shortcut, tab selection, and unknown")
    func originatingScreenForNonNavigationCases() {
        #expect(ScreenOpenSource<AppScreen>.deepLink(URL(string: "myapp://home")!).originatingScreen == nil)
        #expect(ScreenOpenSource<AppScreen>.shortcut(id: "new-note").originatingScreen == nil)
        #expect(ScreenOpenSource<AppScreen>.tabSelection.originatingScreen == nil)
        #expect(ScreenOpenSource<AppScreen>.unknown.originatingScreen == nil)
    }

    @Test("isPop is true only for .pop")
    func isPopHelper() {
        #expect(ScreenOpenSource.pop(from: AppScreen.home).isPop)
        #expect(!ScreenOpenSource.push(from: AppScreen.home).isPop)
        #expect(!ScreenOpenSource<AppScreen>.tabSelection.isPop)
    }

    @Test("Equatable compares by case and payload")
    func equatable() {
        #expect(ScreenOpenSource.push(from: AppScreen.home) == ScreenOpenSource.push(from: AppScreen.home))
        #expect(ScreenOpenSource.push(from: AppScreen.home) != ScreenOpenSource.push(from: AppScreen.settings))
        #expect(ScreenOpenSource.push(from: AppScreen.home) != ScreenOpenSource.pop(from: AppScreen.home))
        #expect(ScreenOpenSource<AppScreen>.tabSelection == ScreenOpenSource<AppScreen>.tabSelection)
    }

    @Test("Hashable values work in a Set")
    func hashable() {
        let sources: Set<ScreenOpenSource<AppScreen>> = [
            .push(from: .home),
            .push(from: .home),
            .pop(from: .home),
            .tabSelection
        ]
        #expect(sources.count == 3)
    }
}
