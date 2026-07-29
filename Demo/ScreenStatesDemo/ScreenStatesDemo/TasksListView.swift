import UIKit

/// Plain UIKit content view for the `.data` case of the Tasks screen — a
/// simple checklist built from a stack of rows.
final class TasksListView: UIView {
    init(tasks: [DemoTask]) {
        super.init(frame: .zero)
        backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: tasks.map(Self.makeRow))
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private static func makeRow(for task: DemoTask) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: task.isDone ? "checkmark.circle.fill" : "circle"))
        icon.tintColor = task.isDone ? .systemGreen : .secondaryLabel
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = task.title
        label.font = .preferredFont(forTextStyle: .body)

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        return row
    }
}
