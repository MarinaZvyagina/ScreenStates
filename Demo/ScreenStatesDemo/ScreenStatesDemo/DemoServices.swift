import Foundation

/// Simulates a flaky backend: each call takes the "screen" through a
/// different state (empty, populated, failed, populated with different
/// data) so the four `ScreenState` cases are all visible without a real
/// network call.
actor DemoArticleService {
    private var callCount = 0

    func fetchArticles() async throws -> [Article] {
        callCount += 1
        try await Task.sleep(for: .milliseconds(700))
        switch callCount % 4 {
        case 1: return []
        case 2: return Article.samples
        case 3: throw DemoError.network
        default: return Array(Article.samples.prefix(2))
        }
    }
}

actor DemoTaskService {
    private var callCount = 0

    func fetchTasks() async throws -> [DemoTask] {
        callCount += 1
        try await Task.sleep(for: .milliseconds(700))
        switch callCount % 4 {
        case 1: throw DemoError.network
        case 2: return []
        case 3: return DemoTask.samples
        default: return DemoTask.samples.map { DemoTask(title: $0.title, isDone: !$0.isDone) }
        }
    }
}
