import SwiftUI

/// Two screens, two paradigms: "Rey Skywalker" is built with SwiftUI's
/// `ScreenStateView`, "Kylo Ren" is built with UIKit's
/// `ScreenStateContainerView`. Both auto-cycle through Loading, Empty,
/// Data, and Error every couple of seconds to show the whole state
/// machine without any manual interaction — the app also hops between the
/// two tabs on its own, so the whole thing is watchable hands-off.
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
            }
            .task { await autoSwitchTabs() }
        }
    }

    private func autoSwitchTabs() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(6))
            selection = selection == 0 ? 1 : 0
        }
    }
}
