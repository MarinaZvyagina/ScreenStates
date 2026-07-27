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
}
