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

        _ = viewController.view // triggers viewDidLoad()

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
}
#endif
