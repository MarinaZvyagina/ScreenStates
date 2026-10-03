#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Bakes `image` (expected to be a template-rendered SF Symbol) tinted with
/// a linear gradient into a single bitmap, so it can be shown with a plain
/// `UIImageView` — no `CALayer` mask involved. A `CAGradientLayer` masked by
/// another view's layer only paints correctly once both layers have been
/// through at least one Core Animation commit with real geometry; a mask
/// view that's never added to the view hierarchy (as here) isn't guaranteed
/// to get one before the very first commit, and a freshly-created view
/// composited into its superview immediately (as ``ScreenStateDefaultErrorUIView``
/// is on every `.error` transition) can lose that race and render nothing
/// at all. Compositing the gradient into a bitmap up front sidesteps the
/// race entirely: drawing happens synchronously, sized to `image.size`, with
/// no dependency on Auto Layout or the view's own first layout pass.
private func gradientTintedImage(_ image: UIImage, colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    return renderer.image { context in
        image.draw(at: .zero)
        context.cgContext.setBlendMode(.sourceIn)
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map(\.cgColor) as CFArray,
            locations: nil
        ) else { return }
        context.cgContext.drawLinearGradient(
            gradient,
            start: CGPoint(x: startPoint.x * image.size.width, y: startPoint.y * image.size.height),
            end: CGPoint(x: endPoint.x * image.size.width, y: endPoint.y * image.size.height),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }
}

/// Default placeholder shown while a screen's data is loading.
public final class ScreenStateDefaultLoadingUIView: UIView {
    /// Internal (not `private`) so `@testable import` tests can verify the
    /// gradient stops without any rendering — this module's test target
    /// has no live window/scene to snapshot a real render into.
    let gradientRing = GradientUIView()
    private let ringMask = CAShapeLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusDidChange),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(darkerSystemColorsStatusDidChange),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setUp() {
        accessibilityIdentifier = "screenStates.loading"
        isAccessibilityElement = true
        accessibilityLabel = .screenStatesLoading

        gradientRing.gradientLayer.type = .conic
        gradientRing.translatesAutoresizingMaskIntoConstraints = false

        ringMask.fillColor = UIColor.clear.cgColor
        ringMask.strokeColor = UIColor.black.cgColor
        ringMask.lineWidth = 4
        ringMask.lineCap = .round
        ringMask.strokeStart = 0
        ringMask.strokeEnd = 0.75
        gradientRing.layer.mask = ringMask

        addSubview(gradientRing)
        NSLayoutConstraint.activate([
            gradientRing.centerXAnchor.constraint(equalTo: centerXAnchor),
            gradientRing.centerYAnchor.constraint(equalTo: centerYAnchor),
            gradientRing.widthAnchor.constraint(equalToConstant: 44),
            gradientRing.heightAnchor.constraint(equalToConstant: 44)
        ])

        updateRotation()
        updateGradientColors()
    }

    /// Adds the spin animation, unless Reduce Motion is on, in which case
    /// the animation is removed instead and the ring stays static. Also
    /// called when Reduce Motion is toggled live, so an already-visible
    /// spinner responds immediately instead of only on the next appearance.
    @objc
    private func reduceMotionStatusDidChange() {
        updateRotation()
    }

    private func updateRotation() {
        updateRotation(reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// `UIAccessibility.isReduceMotionEnabled` itself is a read-only system
    /// setting that can't be toggled in a test environment.
    func updateRotation(reduceMotion: Bool) {
        guard !reduceMotion else {
            gradientRing.layer.removeAnimation(forKey: "rotation")
            return
        }
        guard gradientRing.layer.animation(forKey: "rotation") == nil else { return }
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1
        rotation.repeatCount = .infinity
        gradientRing.layer.add(rotation, forKey: "rotation")
    }

    /// Swaps the ring's gradient for a solid `.label` tint when Increase
    /// Contrast is on. Also called when Increase Contrast is toggled live,
    /// so an already-visible spinner responds immediately instead of only
    /// on the next appearance.
    @objc
    private func darkerSystemColorsStatusDidChange() {
        updateGradientColors()
    }

    private func updateGradientColors() {
        updateGradientColors(isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// `UIAccessibility.isDarkerSystemColorsEnabled` itself is a read-only
    /// system setting that can't be toggled in a test environment.
    func updateGradientColors(isDarkerSystemColorsEnabled: Bool) {
        gradientRing.gradientLayer.colors = isDarkerSystemColorsEnabled
            ? [UIColor.label.cgColor, UIColor.label.cgColor]
            : [
                UIColor.systemPink.cgColor,
                UIColor.systemOrange.cgColor,
                UIColor.systemYellow.cgColor,
                UIColor.systemPink.cgColor
            ]
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = gradientRing.bounds
        ringMask.frame = bounds
        ringMask.path = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: min(bounds.width, bounds.height) / 2 - ringMask.lineWidth / 2,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        ).cgPath
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        UIAccessibility.post(notification: .announcement, argument: String.screenStatesLoading)
    }
}

/// Default placeholder shown when a screen has no data to display.
public final class ScreenStateDefaultEmptyUIView: UIView {
    /// Internal (not `private`) so `@testable import` tests can verify the
    /// rendered icon's colors — this module's test target has no live
    /// window/scene to snapshot the whole view hierarchy into.
    let iconView = UIImageView()
    /// Internal (not `private`) so `@testable import` tests can verify the
    /// label scales with Dynamic Type — this module's test target has no
    /// live window/scene to snapshot the whole view hierarchy into.
    let titleLabel = UILabel()
    private let symbol: UIImage?

    public init(title: String = .screenStatesNothingHere, systemImage: String = "tray.fill") {
        symbol = UIImage(systemName: systemImage, withConfiguration: UIImage.SymbolConfiguration(pointSize: 56, weight: .regular))
        super.init(frame: .zero)
        setUp(title: title)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(darkerSystemColorsStatusDidChange),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setUp(title: String) {
        accessibilityIdentifier = "screenStates.empty"

        updateIcon()
        // .scaleAspectFit, not .center: SF Symbols aren't square at a given
        // point size (e.g. "tray.fill" at 56pt renders ~79x54), so .center
        // would clip a wider-than-tall icon against this fixed square box.
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textColor = .secondaryLabel
        updateFont()
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])
    }

    /// Swaps the icon's gradient for a solid `.label` tint when Increase
    /// Contrast is on. Also called when Increase Contrast is toggled live,
    /// so an already-visible placeholder responds immediately instead of
    /// only on the next appearance.
    @objc
    private func darkerSystemColorsStatusDidChange() {
        updateIcon()
    }

    private func updateIcon() {
        updateIcon(isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// `UIAccessibility.isDarkerSystemColorsEnabled` itself is a read-only
    /// system setting that can't be toggled in a test environment.
    func updateIcon(isDarkerSystemColorsEnabled: Bool) {
        guard let symbol else { return }
        iconView.image = isDarkerSystemColorsEnabled
            ? symbol.withTintColor(.label, renderingMode: .alwaysOriginal)
            : gradientTintedImage(
                symbol,
                colors: [UIColor.systemPink, .systemOrange, .systemYellow],
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
    }

    private func updateFont() {
        updateFont(contentSizeCategory: traitCollection.preferredContentSizeCategory)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// the system's actual Dynamic Type setting can't be changed in a test
    /// environment.
    func updateFont(contentSizeCategory: UIContentSizeCategory) {
        titleLabel.font = .preferredFont(
            forTextStyle: .body,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: contentSizeCategory)
        )
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        UIAccessibility.post(notification: .announcement, argument: titleLabel.text)
    }
}

/// A `UIView` backed by a `CAGradientLayer`, used by
/// ``ScreenStateDefaultLoadingUIView``'s spinning ring — UIKit's equivalent
/// of SwiftUI's `.foregroundStyle(LinearGradient(...))`. Internal (not
/// `private`) so `@testable import` tests can reach it.
final class GradientUIView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }
}

/// Default placeholder shown when a screen's data failed to load, with an
/// optional Retry button.
public final class ScreenStateDefaultErrorUIView: UIView {
    /// Internal (not `private`) so `@testable import` tests can verify the
    /// rendered icon's colors — this module's test target has no live
    /// window/scene to snapshot the whole view hierarchy into.
    let iconView = UIImageView()
    /// Internal (not `private`) so `@testable import` tests can verify the
    /// label scales with Dynamic Type — this module's test target has no
    /// live window/scene to snapshot the whole view hierarchy into.
    let messageLabel = UILabel()
    private let retryButton = UIButton(configuration: .borderedTinted())
    private let onRetry: (() -> Void)?
    private let symbol: UIImage?

    public init(error: Error, onRetry: (() -> Void)? = nil) {
        self.onRetry = onRetry
        symbol = UIImage(
            systemName: "exclamationmark.triangle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
        )
        super.init(frame: .zero)
        setUp(message: error.localizedDescription, showsRetry: onRetry != nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(darkerSystemColorsStatusDidChange),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setUp(message: String, showsRetry: Bool) {
        accessibilityIdentifier = "screenStates.error"

        updateIcon()
        // .scaleAspectFit, not .center: SF Symbols aren't square at a given
        // point size (e.g. "tray.fill" at 56pt renders ~79x54), so .center
        // would clip a wider-than-tall icon against this fixed square box.
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
        updateFont()
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.borderedTinted()
        configuration.title = .screenStatesRetry
        retryButton.configuration = configuration
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
        retryButton.isHidden = !showsRetry
        retryButton.accessibilityIdentifier = "screenStates.error.retryButton"

        let stack = UIStackView(arrangedSubviews: [iconView, messageLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])
    }

    /// Swaps the icon's gradient for a solid `.label` tint when Increase
    /// Contrast is on. Also called when Increase Contrast is toggled live,
    /// so an already-visible placeholder responds immediately instead of
    /// only on the next appearance.
    @objc
    private func darkerSystemColorsStatusDidChange() {
        updateIcon()
    }

    private func updateIcon() {
        updateIcon(isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// `UIAccessibility.isDarkerSystemColorsEnabled` itself is a read-only
    /// system setting that can't be toggled in a test environment.
    func updateIcon(isDarkerSystemColorsEnabled: Bool) {
        guard let symbol else { return }
        iconView.image = isDarkerSystemColorsEnabled
            ? symbol.withTintColor(.label, renderingMode: .alwaysOriginal)
            : gradientTintedImage(
                symbol,
                colors: [UIColor.systemRed, .systemOrange],
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 1, y: 1)
            )
    }

    private func updateFont() {
        updateFont(contentSizeCategory: traitCollection.preferredContentSizeCategory)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// the system's actual Dynamic Type setting can't be changed in a test
    /// environment.
    func updateFont(contentSizeCategory: UIContentSizeCategory) {
        messageLabel.font = .preferredFont(
            forTextStyle: .body,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: contentSizeCategory)
        )
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        UIAccessibility.post(notification: .announcement, argument: "\(String.screenStatesSomethingWentWrong). \(messageLabel.text ?? "")")
    }

    #if os(tvOS)
    /// Sends focus straight to the Retry button (when shown) instead of
    /// making the Siri Remote user hunt for it.
    public override var preferredFocusEnvironments: [UIFocusEnvironment] {
        retryButton.isHidden ? super.preferredFocusEnvironments : [retryButton]
    }
    #endif
}
#endif
