import Foundation
import Testing
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import ScreenStates

#if canImport(SwiftUI)
@Suite("View.screenState(_:onRetry:content:)")
@MainActor
struct ScreenStateViewModifierTests {
    private struct SampleError: Error {}

    @Test("invokes content with the wrapped value for .data")
    func dataInvokesContent() {
        var receivedValue: Int?
        let view = EmptyView().screenState(.data(42)) { value -> EmptyView in
            receivedValue = value
            return EmptyView()
        }
        _ = view.body
        #expect(receivedValue == 42)
    }

    @Test("does not invoke content for .empty, .loading, or .error")
    func nonDataDoesNotInvokeContent() {
        var contentCallCount = 0
        func makeView(_ state: ScreenState<Int>) -> some View {
            EmptyView().screenState(state) { _ -> EmptyView in
                contentCallCount += 1
                return EmptyView()
            }
        }

        _ = makeView(.empty).body
        _ = makeView(.loading).body
        _ = makeView(.error(SampleError())).body

        #expect(contentCallCount == 0)
    }

    @Test("the fully-customized overload dispatches content and error correctly")
    func customizedOverloadDispatches() {
        // `empty`/`loading` are built eagerly by ScreenStateView's own
        // initializer regardless of `state` (only `content`/`error` are
        // deferred until `body` runs), so only those two are worth
        // asserting on here.
        var errorCalled = false
        var receivedValue: Int?

        func makeView(_ state: ScreenState<Int>) -> some View {
            EmptyView().screenState(state) { value -> EmptyView in
                receivedValue = value
                return EmptyView()
            } empty: {
                EmptyView()
            } loading: {
                EmptyView()
            } error: { _ in
                errorCalled = true
                return EmptyView()
            }
        }

        _ = makeView(.data(7)).body
        #expect(receivedValue == 7)
        #expect(!errorCalled)

        _ = makeView(.error(SampleError())).body
        #expect(errorCalled)
    }
}
#endif
