import ScreenStates
import UIKit

/// The UIKit half of the demo: the same idea as ``ReyScreen``, but built
/// with ``ScreenStateContainerView`` instead of ``ScreenStateView``. The
/// cycling `Task` is started in `viewWillAppear` and cancelled in
/// `viewWillDisappear`, the UIKit analogue of SwiftUI's `.task { }`. Also
/// exercises `secondaryAction` (`screenStates.error.secondaryActionButton`):
/// "Use Cached Data" shows `CharacterFact.kyloRenSamples` directly instead
/// of retrying the network, pausing the auto-cycle for a few seconds so
/// it's visible — a more realistic use for a second button than another
/// retry.
final class KyloRenViewController: UIViewController {
    private let store = ScreenStateStore<[CharacterFact]>()
    private let service = KyloRenFactsService()
    private var cycleTask: Task<Void, Never>?

    private lazy var container = ScreenStateContainerView<[CharacterFact]>(
        onRetry: { [weak self] in self?.reload() },
        secondaryAction: (title: "Use Cached Data", action: { [weak self] in self?.useCachedData() })
    ) { facts in
        CharacterFactsListView(facts: facts, tintColor: .systemRed)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Kylo Ren"
        view.backgroundColor = .systemBackground

        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        container.bind(to: store)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard cycleTask == nil else { return }
        cycleTask = Self.makeCycleTask(store: store, service: service)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cycleTask?.cancel()
        cycleTask = nil
    }

    private func reload() {
        cycleTask?.cancel()
        cycleTask = Self.makeCycleTask(store: store, service: service)
    }

    /// Shows cached data directly, pausing the auto-cycle for a few
    /// seconds so it's actually visible before `loadCollection(_:)`
    /// would otherwise overwrite it with `.loading`.
    private func useCachedData() {
        cycleTask?.cancel()
        store.setData(CharacterFact.kyloRenSamples)
        cycleTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self, !Task.isCancelled else { return }
            self.cycleTask = Self.makeCycleTask(store: self.store, service: self.service)
        }
    }

    /// Free of any reference to `self`, so restarting it on retry never
    /// risks retaining the view controller.
    private static func makeCycleTask(
        store: ScreenStateStore<[CharacterFact]>,
        service: KyloRenFactsService
    ) -> Task<Void, Never> {
        Task {
            while !Task.isCancelled {
                await store.loadCollection { try await service.fetchFacts() }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
}
