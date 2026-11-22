// ScreenStateContainerView itself only compiles under this same guard
// (UIKit isn't available on macOS, and isn't a good fit on watchOS).
#if canImport(UIKit) && !os(watchOS)
import Testing
import UIKit
@testable import ScreenStates

/// Covers `bind(to:)` rebinding to a different store mid-lifecycle — a
/// scenario the SwiftUI side has no equivalent of to begin with
/// (`ScreenStateView` just takes `state` as a value parameter, so there's
/// no persistent subscription that could outlive a "rebind"), but which
/// `ScreenStateContainerView`'s manual Observation-framework bridging has
/// to get right by hand.
@Suite("ScreenStateContainerView")
@MainActor
struct ScreenStateContainerViewTests {
    @Test("bind(to:) mirrors the store's current state immediately")
    func bindMirrorsInitialState() {
        let container = ScreenStateContainerView<Int>(content: { _ in UIView() })
        let store = ScreenStateStore<Int>(.data(1))

        container.bind(to: store)

        #expect(container.state == .data(1))
    }

    @Test("bind(to:) keeps mirroring the store's state after it changes")
    func bindTracksSubsequentChanges() async {
        let container = ScreenStateContainerView<Int>(content: { _ in UIView() })
        let store = ScreenStateStore<Int>(.empty)
        container.bind(to: store)

        store.setData(1)
        // Observation's onChange re-subscription needs a MainActor hop.
        await Task.yield()
        await Task.yield()

        #expect(container.state == .data(1))
    }

    @Test("bind(to:) a different store immediately reflects its state instead of the previous store's")
    func rebindReflectsNewStoreImmediately() {
        let container = ScreenStateContainerView<Int>(content: { _ in UIView() })
        let storeA = ScreenStateStore<Int>(.data(1))
        let storeB = ScreenStateStore<Int>(.data(2))

        container.bind(to: storeA)
        container.bind(to: storeB)

        #expect(container.state == .data(2))
    }

    @Test("bind(to:) a different store stops reacting to the previous store's later changes")
    func rebindStopsObservingThePreviousStore() async {
        let container = ScreenStateContainerView<Int>(content: { _ in UIView() })
        let storeA = ScreenStateStore<Int>(.data(1))
        let storeB = ScreenStateStore<Int>(.data(2))

        container.bind(to: storeA)
        container.bind(to: storeB)

        // storeA's observation chain, left to re-subscribe unconditionally,
        // would overwrite container.state with storeA's new value here —
        // exactly the regression this test locks in against.
        storeA.setData(99)
        await Task.yield()
        await Task.yield()

        #expect(container.state == .data(2))
    }

    @Test("bind(to:) a different store still reacts to that new store's later changes")
    func rebindStillObservesTheNewStore() async {
        let container = ScreenStateContainerView<Int>(content: { _ in UIView() })
        let storeA = ScreenStateStore<Int>(.data(1))
        let storeB = ScreenStateStore<Int>(.data(2))

        container.bind(to: storeA)
        container.bind(to: storeB)

        storeB.setData(3)
        await Task.yield()
        await Task.yield()

        #expect(container.state == .data(3))
    }

    @Test("delegate is notified when the bound store's isRefreshing/refreshError change")
    func delegateNotifiedOfRefreshingAndError() async {
        let container = ScreenStateContainerView<Int>(content: { _ in UIView() })
        let delegate = SpyContainerDelegate()
        container.delegate = delegate
        let store = ScreenStateStore<Int>(.data(1))
        container.bind(to: store)

        await store.refresh { throw SampleError() }
        // isRefreshing's final true -> false transition happens in a
        // defer right as refresh(_:) returns, with no further await left
        // for its pending re-subscription to naturally run against.
        await Task.yield()
        await Task.yield()

        #expect(delegate.isRefreshingUpdates == [true, false])
        #expect(delegate.refreshErrorUpdates.count == 1)
        #expect(delegate.refreshErrorUpdates[0] is SampleError)
    }

    @Test("delegate reflects the newly-bound store after a rebind, not the previous one")
    func delegateReflectsNewStoreAfterRebind() async {
        let container = ScreenStateContainerView<Int>(content: { _ in UIView() })
        let delegate = SpyContainerDelegate()
        container.delegate = delegate
        let storeA = ScreenStateStore<Int>(.data(1))
        let storeB = ScreenStateStore<Int>(.data(2))
        container.bind(to: storeA)
        container.bind(to: storeB)

        // storeA refreshing/failing after the rebind must not reach the
        // delegate — same regression class as the state-corruption tests
        // above, just for isRefreshing/refreshError instead of state.
        await storeA.refresh { throw SampleError() }
        await Task.yield()
        await Task.yield()
        #expect(delegate.isRefreshingUpdates.isEmpty)
        #expect(delegate.refreshErrorUpdates.isEmpty)

        await storeB.refresh { throw SampleError() }
        await Task.yield()
        await Task.yield()
        #expect(delegate.isRefreshingUpdates == [true, false])
        #expect(delegate.refreshErrorUpdates.count == 1)
    }

    @Test("the built-in-placeholders init wires secondaryAction through to the default error view")
    func convenienceInitWiresSecondaryAction() {
        var tapped = false
        let container = ScreenStateContainerView<Int>(
            secondaryAction: (title: "Go Back", action: { tapped = true })
        ) { _ in UIView() }
        container.state = .error(SampleError())

        let errorView = container.subviews.compactMap { $0 as? ScreenStateDefaultErrorUIView }.first
        #expect(errorView != nil)
        errorView?.secondaryActionButton.sendActions(for: .touchUpInside)
        #expect(tapped)
    }

    // `UIRefreshControl` is unavailable on tvOS -- the whole feature is a
    // no-op there, mirroring the production guard in
    // ScreenStateContainerView.swift.
    #if os(iOS) || os(visionOS)
    @Test("pullToRefresh attaches a UIRefreshControl when the .data content view is a UIScrollView")
    func pullToRefreshAttachesToScrollView() {
        let container = ScreenStateContainerView<Int>(pullToRefresh: {}) { _ in UIScrollView() }
        container.state = .data(1)

        let scrollView = container.subviews.compactMap { $0 as? UIScrollView }.first
        #expect(scrollView?.refreshControl != nil)
    }

    @Test("pullToRefresh does nothing when the .data content view isn't a UIScrollView")
    func pullToRefreshNoOpForNonScrollView() {
        let container = ScreenStateContainerView<Int>(pullToRefresh: {}) { _ in UIView() }
        container.state = .data(1)
        // Just confirming this doesn't crash -- there's no UIScrollView to
        // inspect a refreshControl on.
        #expect(container.subviews.first is UIView)
    }

    // `UIRefreshControl.isRefreshing` never actually flips in this test
    // host: `beginRefreshing()` is a silent no-op "offscreen" (confirmed
    // empirically -- logs `A UIRefreshControl received offscreen
    // beginRefreshing. Ignored.` -- even after attaching the container to
    // a real `UIWindow` with an explicit frame and a forced layout pass;
    // a SwiftPM test target has no actual `UIWindowScene`/app lifecycle to
    // satisfy it). So this test only checks the one real signal available
    // without that: `pullToRefresh` itself got called.
    @Test("pulling to refresh calls pullToRefresh")
    func pullToRefreshCallsClosure() async {
        nonisolated(unsafe) var callCount = 0
        let container = ScreenStateContainerView<Int>(pullToRefresh: { callCount += 1 }) { _ in UIScrollView() }
        container.state = .data(1)

        let scrollView = container.subviews.compactMap { $0 as? UIScrollView }.first
        scrollView?.refreshControl?.sendActions(for: .valueChanged)

        // The action kicks off an unstructured Task; give it a chance to run.
        await Task.yield()
        await Task.yield()

        #expect(callCount == 1)
    }
    #endif
}

private struct SampleError: Error {}

@MainActor
private final class SpyContainerDelegate: ScreenStateContainerViewDelegate {
    private(set) var isRefreshingUpdates: [Bool] = []
    private(set) var refreshErrorUpdates: [Error] = []

    func screenStateContainerViewDidUpdateIsRefreshing(_ isRefreshing: Bool) {
        isRefreshingUpdates.append(isRefreshing)
    }

    func screenStateContainerViewDidUpdateRefreshError(_ error: Error?) {
        if let error {
            refreshErrorUpdates.append(error)
        }
    }
}
#endif
