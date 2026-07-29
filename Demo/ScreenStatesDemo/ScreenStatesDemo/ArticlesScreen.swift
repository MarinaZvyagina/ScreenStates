import ScreenStates
import SwiftUI

/// The SwiftUI half of the demo: a list screen driven entirely by
/// `ScreenStateStore` + `ScreenStateView`. `autoCycle()` repeatedly calls
/// `loadCollection(_:)`, so opening this tab walks through Loading, Empty,
/// Data, and Error on its own — the same call the Retry button makes.
struct ArticlesScreen: View {
    @State private var store = ScreenStateStore<[Article]>()
    private let service = DemoArticleService()

    var body: some View {
        NavigationStack {
            ScreenStateView(store.state, onRetry: reload) { articles in
                List(articles) { article in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title)
                            .font(.headline)
                        Text(article.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Articles")
        }
        .task { await autoCycle() }
    }

    private func reload() {
        Task { await store.loadCollection { try await service.fetchArticles() } }
    }

    private func autoCycle() async {
        while !Task.isCancelled {
            await store.loadCollection { try await service.fetchArticles() }
            try? await Task.sleep(for: .seconds(2))
        }
    }
}

#Preview {
    ArticlesScreen()
}
