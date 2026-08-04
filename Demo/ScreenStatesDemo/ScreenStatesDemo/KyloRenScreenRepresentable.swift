import SwiftUI
import UIKit

/// Hosts the UIKit `KyloRenViewController` (inside a `UINavigationController`
/// for a matching nav bar) so it can sit alongside the SwiftUI screen in the
/// demo's `TabView`.
struct KyloRenScreenRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: KyloRenViewController())
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
