import Foundation
import Testing
@testable import ScreenStates

@Suite("ScreenAnalyticsEvent")
struct ScreenAnalyticsEventTests {
    @Test("screenOpened(screen:source:) sets the screen and, when given, the source")
    func screenOpened() {
        let withoutSource = ScreenAnalyticsEvent.screenOpened(screen: "Articles")
        #expect(withoutSource.name == "screen_opened")
        #expect(withoutSource.parameters == ["screen": .string("Articles")])

        let withSource = ScreenAnalyticsEvent.screenOpened(screen: "Articles", source: "push")
        #expect(withSource.parameters == ["screen": .string("Articles"), "source": .string("push")])
    }

    @Test("screenStateChanged(screen:from:to:errorDescription:) sets the transition and, when given, the error")
    func screenStateChanged() {
        let withoutError = ScreenAnalyticsEvent.screenStateChanged(screen: "Articles", from: "loading", to: "data")
        #expect(withoutError.name == "screen_state_changed")
        #expect(withoutError.parameters == [
            "screen": .string("Articles"),
            "from": .string("loading"),
            "to": .string("data")
        ])

        let withError = ScreenAnalyticsEvent.screenStateChanged(
            screen: "Articles",
            from: "loading",
            to: "error",
            errorDescription: "offline"
        )
        #expect(withError.parameters["error"] == .string("offline"))
    }

    @Test("ScreenState.analyticsKind names every case")
    func screenStateAnalyticsKind() {
        #expect(ScreenState<Int>.empty.analyticsKind == "empty")
        #expect(ScreenState<Int>.loading.analyticsKind == "loading")
        #expect(ScreenState<Int>.data(1).analyticsKind == "data")
        #expect(ScreenState<Int>.error(NSError(domain: "", code: 0)).analyticsKind == "error")
    }

    @Test("ScreenOpenSource.analyticsKind names every case")
    func screenOpenSourceAnalyticsKind() {
        #expect(ScreenOpenSource.push(from: "home").analyticsKind == "push")
        #expect(ScreenOpenSource.pop(from: "home").analyticsKind == "pop")
        #expect(ScreenOpenSource.presented(from: "home").analyticsKind == "presented")
        #expect(ScreenOpenSource<String>.deepLink(URL(string: "myapp://home")!).analyticsKind == "deep_link")
        #expect(ScreenOpenSource<String>.shortcut(id: "new-note").analyticsKind == "shortcut")
        #expect(ScreenOpenSource<String>.tabSelection.analyticsKind == "tab_selection")
        #expect(ScreenOpenSource<String>.unknown.analyticsKind == "unknown")
    }
}

@Suite("AnalyticsValue")
struct AnalyticsValueTests {
    @Test("description formats every case as plain text")
    func description() {
        #expect(AnalyticsValue.string("Articles").description == "Articles")
        #expect(AnalyticsValue.int(3).description == "3")
        #expect(AnalyticsValue.double(1.5).description == "1.5")
        #expect(AnalyticsValue.bool(true).description == "true")
    }
}

@Suite("Convenience trackers")
@MainActor
struct ConvenienceTrackerTests {
    @Test("PrintScreenAnalyticsTracker accepts any event without crashing")
    func printTrackerHandlesEvents() {
        let tracker = PrintScreenAnalyticsTracker()
        tracker.track(.screenOpened(screen: "Articles", source: "push"))
        tracker.track(.screenStateChanged(screen: "Articles", from: "loading", to: "data"))
    }

    @Test("NoOpScreenAnalyticsTracker accepts any event and does nothing")
    func noOpTrackerHandlesEvents() {
        let tracker = NoOpScreenAnalyticsTracker()
        tracker.track(.screenOpened(screen: "Articles"))
    }
}

@Suite("ScreenAnalyticsService")
@MainActor
struct ScreenAnalyticsServiceTests {
    private struct SampleError: LocalizedError {
        var errorDescription: String? { "sample failure" }
    }

    @Test("track(_:) fans an event out to every registered tracker")
    func trackFansOutToAllTrackers() {
        let first = SpyTracker()
        let second = SpyTracker()
        let service = ScreenAnalyticsService(trackers: [first, second])

        service.track(.screenOpened(screen: "Articles"))

        #expect(first.events == [.screenOpened(screen: "Articles")])
        #expect(second.events == [.screenOpened(screen: "Articles")])
    }

    @Test("trackScreenOpened(_:source:) tracks a screen_opened event")
    func trackScreenOpened() {
        let spy = SpyTracker()
        let service = ScreenAnalyticsService(trackers: [spy])

        service.trackScreenOpened("Articles", source: ScreenOpenSource.push(from: "Home").analyticsKind)

        #expect(spy.events == [.screenOpened(screen: "Articles", source: "push")])
    }

    @Test("observeStateChanges(of:screen:) tracks each ScreenState transition")
    func observeStateChangesTracksTransitions() async {
        let store = ScreenStateStore<Int>(.empty)
        let spy = SpyTracker()
        let service = ScreenAnalyticsService(trackers: [spy])
        service.observeStateChanges(of: store, screen: "Test")

        store.setLoading()
        await spy.waitUntil(count: 1)

        // loading -> data also fires a screen_load_duration event (covered
        // in detail by the ScreenLoadDurationTests suite below), so this
        // waits for both.
        store.setData(1)
        await spy.waitUntil(count: 3)

        // data -> error never passed through .loading, so no duration event.
        store.setError(SampleError())
        await spy.waitUntil(count: 4)

        #expect(spy.events[0] == .screenStateChanged(screen: "Test", from: "empty", to: "loading"))
        #expect(spy.events[1] == .screenStateChanged(screen: "Test", from: "loading", to: "data"))
        #expect(spy.events[2].name == "screen_load_duration")
        #expect(spy.events[3] == .screenStateChanged(screen: "Test", from: "data", to: "error", errorDescription: "sample failure"))
    }
}

@Suite("ScreenAnalyticsService load duration tracking")
@MainActor
struct ScreenLoadDurationTests {
    private struct SampleError: Error {}

    @Test("observeStateChanges(of:screen:) tracks screen_load_duration when .loading resolves to .data, .empty, or .error")
    func loadDurationForEveryOutcome() async {
        for (transition, outcome) in [
            ({ (store: ScreenStateStore<Int>) in store.setData(1) }, "data"),
            ({ (store: ScreenStateStore<Int>) in store.setEmpty() }, "empty"),
            ({ (store: ScreenStateStore<Int>) in store.setError(SampleError()) }, "error")
        ] {
            let store = ScreenStateStore<Int>(.empty)
            let spy = SpyTracker()
            let service = ScreenAnalyticsService(trackers: [spy])
            service.observeStateChanges(of: store, screen: "Test")

            store.setLoading()
            await spy.waitUntil(count: 1)

            transition(store)
            await spy.waitUntil(count: 3)

            let durationEvent = spy.events[2]
            #expect(durationEvent.name == "screen_load_duration")
            #expect(durationEvent.parameters["screen"] == .string("Test"))
            #expect(durationEvent.parameters["outcome"] == .string(outcome))
            guard case .int(let milliseconds)? = durationEvent.parameters["duration_ms"] else {
                Issue.record("duration_ms missing or not an .int")
                continue
            }
            #expect(milliseconds >= 0)
        }
    }

    @Test("a transition that doesn't leave .loading, or never entered it, doesn't track a duration")
    func noDurationWithoutLeavingLoading() async {
        let store = ScreenStateStore<Int>(.empty)
        let spy = SpyTracker()
        let service = ScreenAnalyticsService(trackers: [spy])
        service.observeStateChanges(of: store, screen: "Test")

        store.setData(1)
        await spy.waitUntil(count: 1)

        store.setError(SampleError())
        await spy.waitUntil(count: 2)

        #expect(spy.events.map(\.name) == ["screen_state_changed", "screen_state_changed"])
    }

    @Test("observing a store that's already .loading tracks the duration of its first resolution")
    func loadDurationWhenAlreadyLoadingBeforeObserving() async {
        let store = ScreenStateStore<Int>() // defaults to .loading
        let spy = SpyTracker()
        let service = ScreenAnalyticsService(trackers: [spy])
        service.observeStateChanges(of: store, screen: "Test")

        store.setData(1)
        await spy.waitUntil(count: 2)

        #expect(spy.events[0] == .screenStateChanged(screen: "Test", from: "loading", to: "data"))
        #expect(spy.events[1].name == "screen_load_duration")
        #expect(spy.events[1].parameters["outcome"] == .string("data"))
    }
}

/// A ``ScreenAnalyticsTracker`` test double that records every tracked
/// event and can await a specific count, so tests don't have to guess how
/// many run-loop turns an async `withObservationTracking` re-subscription
/// needs.
@MainActor
private final class SpyTracker: ScreenAnalyticsTracker {
    private(set) var events: [ScreenAnalyticsEvent] = []
    private var continuation: CheckedContinuation<Void, Never>?
    private var target = 0

    func track(_ event: ScreenAnalyticsEvent) {
        events.append(event)
        if events.count >= target {
            continuation?.resume()
            continuation = nil
        }
    }

    func waitUntil(count: Int) async {
        guard events.count < count else { return }
        target = count
        await withCheckedContinuation { continuation = $0 }
    }
}
