import XCTest

/// Drives the real app through all four `ScreenState` cases end-to-end,
/// catching an integration regression (wrong view wired up, a state
/// transition that never fires, an identifier that silently stops being
/// applied) the package's own unit suite can't: that suite exercises
/// `ScreenStateStore` and the default placeholders in isolation, never the
/// two actually assembled into a real screen inside a real app.
///
/// The Rey tab's `ReyFactsService` cycles deterministically by call count
/// (`callCount % 4`): empty, then a full data set, then an error, then a
/// smaller data set, then repeats — see `DemoServices.swift`. This test
/// rides that real cycle rather than taking any shortcut to force a
/// state, but doesn't assume which point in the cycle it happens to catch
/// first: app launch/warm-up time before the test starts polling is real
/// but unpredictable, and the cycle has already been running since
/// `ReyScreen` appeared regardless. So this polls for all four states to
/// each occur at least once within one generous window, instead of
/// asserting a strict order tied to assuming it's seeing callCount == 1.
///
/// `-UITesting` disables the app's own hands-off auto-tab-switching (see
/// `ScreenStatesDemoApp.autoSwitchTabs()`), which would otherwise carry
/// the test away from the Rey tab mid-cycle.
final class ScreenStatesDemoUITests: XCTestCase {
    func testReyScreenCyclesThroughAllFourStates() {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        app.launch()

        app.tabBars.buttons["Rey"].tap()

        var seenLoading = false
        var seenEmpty = false
        var seenError = false
        var seenData = false

        // One full cycle (loading + empty/data/error, four times over) is
        // well under 15 seconds; this covers more than one full cycle so
        // a slow start before the test begins polling can't cost a state.
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline, !(seenLoading && seenEmpty && seenError && seenData) {
            if app.descendants(matching: .any)["screenStates.loading"].exists {
                seenLoading = true
            }
            if app.descendants(matching: .any)["screenStates.empty"].exists {
                seenEmpty = true
            }
            if app.descendants(matching: .any)["screenStates.error"].exists {
                seenError = true
            }
            if app.staticTexts["Grew up scavenging starship wreckage on the desert world of Jakku."].exists {
                seenData = true
            }
            Thread.sleep(forTimeInterval: 0.2)
        }

        XCTAssertTrue(seenLoading, "Expected the Loading placeholder to appear at some point in the cycle")
        XCTAssertTrue(seenEmpty, "Expected the Empty placeholder to appear at some point in the cycle")
        XCTAssertTrue(seenError, "Expected the Error placeholder to appear at some point in the cycle")
        XCTAssertTrue(seenData, "Expected a fact from the sample set to appear at some point in the cycle")
    }
}
