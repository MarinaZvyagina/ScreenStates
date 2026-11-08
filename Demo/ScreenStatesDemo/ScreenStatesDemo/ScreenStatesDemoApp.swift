import Foundation
import SwiftUI

/// Three screens, two paradigms: "Rey Skywalker" and "Finn" are built with
/// SwiftUI's `ScreenStateView`, "Kylo Ren" with UIKit's
/// `ScreenStateContainerView`. Rey and Kylo Ren auto-cycle through
/// Loading, Empty, Data, and Error every couple of seconds; Finn instead
/// auto-cycles through `loadNextPage(_:)`'s pagination, one page at a
/// time — see `FinnScreen`. All three run without any manual interaction,
/// and the app hops between tabs on its own, so the whole thing is
/// watchable hands-off.
@main
struct ScreenStatesDemoApp: App {
    @State private var selection = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selection) {
                ReyScreen()
                    .tabItem { Label("Rey", systemImage: "sun.max.fill") }
                    .tag(0)

                KyloRenScreenRepresentable()
                    .tabItem { Label("Kylo Ren", systemImage: "flame.fill") }
                    .tag(1)
                    .ignoresSafeArea(edges: .bottom)

                FinnScreen()
                    .tabItem { Label("Finn", systemImage: "shield.lefthalf.filled") }
                    .tag(2)
            }
            .task { await autoSwitchTabs() }
        }
    }

    private func autoSwitchTabs() async {
        // Off under ScreenStatesDemoUITests (`-UITesting` launch argument):
        // it would otherwise switch away from whichever tab the test is
        // watching every 6 seconds, fighting the test rather than the
        // state cycle it's actually trying to observe.
        guard !ProcessInfo.processInfo.arguments.contains("UITesting") else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(6))
            selection = (selection + 1) % 3
        }
    }
}
