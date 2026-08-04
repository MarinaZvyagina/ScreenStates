import ScreenStates
import SwiftUI

/// The SwiftUI half of the demo: a list screen driven entirely by
/// `ScreenStateStore` + `ScreenStateView`. `autoCycle()` repeatedly calls
/// `loadCollection(_:)`, so opening this tab walks through Loading, Empty,
/// Data, and Error on its own — the same call the Retry button makes.
struct ReyScreen: View {
    @State private var store = ScreenStateStore<[CharacterFact]>()
    private let service = ReyFactsService()

    var body: some View {
        NavigationStack {
            ScreenStateView(store.state, onRetry: reload) { facts in
                List(facts) { fact in
                    Label {
                        Text(fact.text)
                    } icon: {
                        Image(systemName: fact.icon)
                            .foregroundStyle(.yellow)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Rey Skywalker")
        }
        .task { await autoCycle() }
    }

    private func reload() {
        Task { await store.loadCollection { try await service.fetchFacts() } }
    }

    private func autoCycle() async {
        while !Task.isCancelled {
            await store.loadCollection { try await service.fetchFacts() }
            try? await Task.sleep(for: .seconds(2))
        }
    }
}

#Preview {
    ReyScreen()
}
