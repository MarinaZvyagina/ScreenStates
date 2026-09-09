#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Default placeholder shown while a screen's data is loading.
public final class ScreenStateDefaultLoadingUIView: UIView {
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func setUp() {
        accessibilityIdentifier = "screenStates.loading"
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        activityIndicator.startAnimating()
    }
}

/// Default placeholder shown when a screen has no data to display.
public final class ScreenStateDefaultEmptyUIView: UIView {
    private let iconMask = UIImageView()
    private let iconGradient = GradientUIView()
    private let titleLabel = UILabel()

    public init(title: String = "Nothing Here", systemImage: String = "tray.fill") {
        super.init(frame: .zero)
        setUp(title: title, systemImage: systemImage)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func setUp(title: String, systemImage: String) {
        accessibilityIdentifier = "screenStates.empty"

        iconMask.image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
        )
        iconMask.contentMode = .center
        iconMask.translatesAutoresizingMaskIntoConstraints = false

        iconGradient.gradientLayer.colors = [
            UIColor.systemPink.cgColor,
            UIColor.systemOrange.cgColor,
            UIColor.systemYellow.cgColor
        ]
        iconGradient.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        iconGradient.gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        iconGradient.mask = iconMask
        iconGradient.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textColor = .secondaryLabel
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconGradient, titleLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            iconGradient.widthAnchor.constraint(equalToConstant: 56),
            iconGradient.heightAnchor.constraint(equalToConstant: 56),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])
    }
}

/// A `UIView` backed by a `CAGradientLayer`, used to paint a solid gradient
/// through another view set as its `mask` (an SF Symbol icon, in
/// ``ScreenStateDefaultEmptyUIView``) — UIKit's equivalent of SwiftUI's
/// `.foregroundStyle(LinearGradient(...))` on an `Image`.
private final class GradientUIView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }
}

/// Default placeholder shown when a screen's data failed to load, with an
/// optional Retry button.
public final class ScreenStateDefaultErrorUIView: UIView {
    private let messageLabel = UILabel()
    private let retryButton = UIButton(configuration: .borderedTinted())
    private let onRetry: (() -> Void)?

    public init(error: Error, onRetry: (() -> Void)? = nil) {
        self.onRetry = onRetry
        super.init(frame: .zero)
        setUp(message: error.localizedDescription, showsRetry: onRetry != nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func setUp(message: String, showsRetry: Bool) {
        accessibilityIdentifier = "screenStates.error"
        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.borderedTinted()
        configuration.title = "Retry"
        retryButton.configuration = configuration
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
        retryButton.isHidden = !showsRetry
        retryButton.accessibilityIdentifier = "screenStates.error.retryButton"

        let stack = UIStackView(arrangedSubviews: [messageLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])
    }
}
#endif
