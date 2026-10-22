// ScreenStateViewController itself only compiles under this same guard
// (UIKit isn't available on macOS, and isn't a good fit on watchOS).
#if canImport(UIKit) && !os(watchOS)
import Foundation
import Testing
import UIKit
@testable import ScreenStates

@Suite("ScreenStateViewController")
@MainActor
struct ScreenStateViewControllerTests {
    private struct SampleError: Error {}

    @Test("viewDidLoad adds the container as a full-bounds subview and binds the store")
    func setsUpContainerAndBindsStore() {
        let store = ScreenStateStore<Int>(.data(42))
        var receivedValue: Int?
        let viewController = ScreenStateViewController(store: store) { value -> UIView in
            receivedValue = value
            return UIView()
        }

        _ = viewController.view  // triggers viewDidLoad()

        #expect(viewController.view.subviews.count == 1)
        #expect(receivedValue == 42)
        #expect(viewController.store === store)
    }

    @Test("the fully-customized initializer wires up the given placeholders")
    func customizedInitializer() {
        let store = ScreenStateStore<Int>(.empty)
        let customEmptyView = UIView()
        var receivedValue: Int?

        let viewController = ScreenStateViewController(
            store: store,
            emptyView: customEmptyView,
            loadingView: UIView(),
            errorView: { _ in UIView() }
        ) { value -> UIView in
            receivedValue = value
            return UIView()
        }

        _ = viewController.view

        #expect(viewController.view.subviews.count == 1)
        #expect(viewController.view.subviews.first?.subviews.first === customEmptyView)
        #expect(receivedValue == nil)
    }

    @Test("state changes on the store propagate to the container after binding")
    func storeChangesPropagate() async {
        let store = ScreenStateStore<Int>(.empty)
        var receivedValue: Int?
        let viewController = ScreenStateViewController(store: store) { value -> UIView in
            receivedValue = value
            return UIView()
        }

        _ = viewController.view
        #expect(receivedValue == nil)

        store.setData(7)
        // Observation's onChange re-subscription needs a MainActor hop.
        await Task.yield()
        await Task.yield()

        #expect(receivedValue == 7)
    }

    @Test("isRefreshingDidChange(_:)/refreshErrorDidChange(_:) are called when the bound store's isRefreshing/refreshError change")
    func refreshHooksForwardFromTheContainerDelegate() async {
        let store = ScreenStateStore<Int>(.data(1))
        let viewController = RefreshTrackingViewController(store: store)
        _ = viewController.view

        await store.refresh { throw SampleError() }
        // isRefreshing's final true -> false transition happens in a
        // defer right as refresh(_:) returns, with no further await left
        // for its pending re-subscription to naturally run against.
        await Task.yield()
        await Task.yield()

        #expect(viewController.isRefreshingUpdates == [true, false])
        #expect(viewController.refreshErrorUpdates.count == 1)
        #expect(viewController.refreshErrorUpdates.first is SampleError)
    }
}

@MainActor
private final class RefreshTrackingViewController: ScreenStateViewController<Int> {
    private(set) var isRefreshingUpdates: [Bool] = []
    private(set) var refreshErrorUpdates: [Error] = []

    init(store: ScreenStateStore<Int>) {
        super.init(store: store) { _ in UIView() }
    }

    override func isRefreshingDidChange(_ isRefreshing: Bool) {
        isRefreshingUpdates.append(isRefreshing)
    }

    override func refreshErrorDidChange(_ error: Error?) {
        if let error {
            refreshErrorUpdates.append(error)
        }
    }
}
#endif
