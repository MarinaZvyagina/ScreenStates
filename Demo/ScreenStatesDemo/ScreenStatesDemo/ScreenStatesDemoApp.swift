import SwiftUI

/// Two screens, two paradigms: "Articles" is built with SwiftUI's
/// `ScreenStateView`, "Tasks" is built with UIKit's
/// `ScreenStateContainerView`. Both auto-cycle through Loading, Empty,
/// Data, and Error every couple of seconds to show the whole state
/// machine without any manual interaction.
@main
struct ScreenStatesDemoApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ArticlesScreen()
                    .tabItem { Label("Articles", systemImage: "newspaper") }

                TasksScreenRepresentable()
                    .tabItem { Label("Tasks", systemImage: "checklist") }
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
