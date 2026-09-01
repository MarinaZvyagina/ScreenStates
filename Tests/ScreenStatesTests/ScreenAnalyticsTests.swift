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

        store.setData(1)
        await spy.waitUntil(count: 2)

        store.setError(SampleError())
        await spy.waitUntil(count: 3)

        #expect(spy.events == [
            .screenStateChanged(screen: "Test", from: "empty", to: "loading"),
            .screenStateChanged(screen: "Test", from: "loading", to: "data"),
            .screenStateChanged(screen: "Test", from: "data", to: "error", errorDescription: "sample failure")
        ])
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
