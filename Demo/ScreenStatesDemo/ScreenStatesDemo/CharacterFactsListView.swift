import UIKit

/// Plain UIKit content view for the `.data` case of the Kylo Ren screen — a
/// simple list of facts built from a stack of rows.
final class CharacterFactsListView: UIView {
    init(facts: [CharacterFact], tintColor: UIColor) {
        super.init(frame: .zero)
        backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: facts.map { Self.makeRow(for: $0, tintColor: tintColor) })
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

    private static func makeRow(for fact: CharacterFact, tintColor: UIColor) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: fact.icon))
        icon.tintColor = tintColor
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = fact.text
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        return row
    }
}
