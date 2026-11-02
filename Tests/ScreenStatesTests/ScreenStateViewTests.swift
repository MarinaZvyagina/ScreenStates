import Foundation
import Testing
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import ScreenStates

#if canImport(SwiftUI)
@Suite("ScreenStateView")
@MainActor
struct ScreenStateViewTests {
    private struct SampleError: Error {}

    @Test("Equatable compares two views with the same state as equal, regardless of their closures")
    func equatableComparesByState() {
        let lhs = ScreenStateView(.data(1)) { (value: Int) -> EmptyView in
            EmptyView()
        }
        let rhs = ScreenStateView(.data(1)) { (value: Int) -> EmptyView in
            _ = value
            return EmptyView()
        }
        #expect(lhs == rhs)
    }

    @Test("Equatable compares two views with a different state as unequal")
    func equatableComparesByStateDifference() {
        let lhs = ScreenStateView(.data(1)) { (_: Int) -> EmptyView in EmptyView() }
        let rhs = ScreenStateView(.data(2)) { (_: Int) -> EmptyView in EmptyView() }
        #expect(lhs != rhs)

        let empty = ScreenStateView(.empty) { (_: Int) -> EmptyView in EmptyView() }
        let loading = ScreenStateView(.loading) { (_: Int) -> EmptyView in EmptyView() }
        #expect(empty != loading)
    }

    @Test("Equatable compares .error states by the same rules as ScreenState itself")
    func equatableComparesErrorStates() {
        let lhs = ScreenStateView(.error(SampleError())) { (_: Int) -> EmptyView in EmptyView() }
        let rhs = ScreenStateView(.error(SampleError())) { (_: Int) -> EmptyView in EmptyView() }
        #expect(lhs == rhs)
    }
}
#endif
