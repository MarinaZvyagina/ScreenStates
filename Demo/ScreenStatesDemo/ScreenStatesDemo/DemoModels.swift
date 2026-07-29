import Foundation

struct Article: Identifiable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String

    init(id: UUID = UUID(), title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

extension Article {
    static let samples: [Article] = [
        Article(title: "Swift 6 Concurrency In Practice", subtitle: "A field guide to strict concurrency checking"),
        Article(title: "What's New in Observation", subtitle: "Replacing Combine in everyday SwiftUI code"),
        Article(title: "Designing Resilient Screens", subtitle: "Empty, Loading, Data, and Error as first-class states")
    ]
}

struct DemoTask: Identifiable, Sendable {
    let id: UUID
    let title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

extension DemoTask {
    static let samples: [DemoTask] = [
        DemoTask(title: "Wire up ScreenStateStore", isDone: true),
        DemoTask(title: "Bind ScreenStateContainerView", isDone: true),
        DemoTask(title: "Ship the demo", isDone: false)
    ]
}

enum DemoError: LocalizedError {
    case network

    var errorDescription: String? {
        "Couldn't reach the server. Check your connection and try again."
    }
}
