import SwiftUI
import UIKit

/// Hosts the UIKit `TasksViewController` (inside a `UINavigationController`
/// for a matching nav bar) so it can sit alongside the SwiftUI screen in the
/// demo's `TabView`.
struct TasksScreenRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: TasksViewController())
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
