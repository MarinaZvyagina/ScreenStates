import ScreenStates
import SwiftUI

/// A third demo screen, alongside ``ReyScreen`` and the Kylo Ren tab: the
/// same SwiftUI `ScreenStateView` as Rey's, but driven by `loadNextPage(_:)`
/// instead of a single `loadCollection(_:)` for everything at once — see
/// `FinnFactsService`. `autoPaginate()` plays the "scroll to load more"
/// interaction automatically: fetches the first page, waits, fetches each
/// following page in turn until the service reports nothing left, then
/// pauses before starting over with a fresh first page — hands-off, like
/// the other two tabs.
struct FinnScreen: View {
    @State private var store = ScreenStateStore<[CharacterFact]>()
    private let service = FinnFactsService()

    var body: some View {
        NavigationStack {
            ScreenStateView(store.state, onRetry: reload) { facts in
                List(facts) { fact in
                    Label {
                        Text(fact.text)
                    } icon: {
                        Image(systemName: fact.icon)
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
                .safeAreaInset(edge: .bottom) {
                    if store.isLoadingNextPage {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(8)
                    }
                }
            }
            .navigationTitle("Finn")
        }
        .task { await autoPaginate() }
    }

    private func reload() {
        Task { await store.loadCollection { try await service.fetchFirstPage() } }
    }

    private func autoPaginate() async {
        while !Task.isCancelled {
            await store.loadCollection { try await service.fetchFirstPage() }
            try? await Task.sleep(for: .seconds(2))

            var pageCount = store.state.value?.count ?? 0
            while !Task.isCancelled {
                await store.loadNextPage { try await service.fetchNextPage() }
                let newPageCount = store.state.value?.count ?? 0
                guard newPageCount > pageCount else { break }  // the service has no more pages
                pageCount = newPageCount
                try? await Task.sleep(for: .seconds(2))
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }
}

#Preview {
    FinnScreen()
}
