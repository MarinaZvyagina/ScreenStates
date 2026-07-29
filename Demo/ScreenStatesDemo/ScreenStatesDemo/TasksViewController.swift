import ScreenStates
import UIKit

/// The UIKit half of the demo: the same idea as ``ArticlesScreen``, but
/// built with ``ScreenStateContainerView`` instead of ``ScreenStateView``.
/// The cycling `Task` is started in `viewWillAppear` and cancelled in
/// `viewWillDisappear`, the UIKit analogue of SwiftUI's `.task { }`.
final class TasksViewController: UIViewController {
    private let store = ScreenStateStore<[DemoTask]>()
    private let service = DemoTaskService()
    private var cycleTask: Task<Void, Never>?

    private lazy var container = ScreenStateContainerView<[DemoTask]>(
        onRetry: { [weak self] in self?.reload() }
    ) { tasks in
        TasksListView(tasks: tasks)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tasks"
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

    /// Free of any reference to `self`, so restarting it on retry never
    /// risks retaining the view controller.
    private static func makeCycleTask(
        store: ScreenStateStore<[DemoTask]>,
        service: DemoTaskService
    ) -> Task<Void, Never> {
        Task {
            while !Task.isCancelled {
                await store.loadCollection { try await service.fetchTasks() }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
}
