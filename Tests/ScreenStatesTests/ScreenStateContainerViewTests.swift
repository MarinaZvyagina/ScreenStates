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
}
#endif
