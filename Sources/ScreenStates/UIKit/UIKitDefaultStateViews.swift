#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Default placeholder sizing — a bit smaller on Mac Catalyst, where a
/// window is driven by a precise pointer rather than a touch target that
/// needs to stay comfortably tappable.
private enum ScreenStatesMetrics {
    #if targetEnvironment(macCatalyst)
    static let iconSize: CGFloat = 48
    static let compactIconSize: CGFloat = 24
    static let spinnerSize: CGFloat = 36
    static let compactSpinnerSize: CGFloat = 20
    static let spinnerLineWidth: CGFloat = 3
    #else
    static let iconSize: CGFloat = 56
    static let compactIconSize: CGFloat = 28
    static let spinnerSize: CGFloat = 44
    static let compactSpinnerSize: CGFloat = 24
    static let spinnerLineWidth: CGFloat = 4
    #endif

    static func iconSize(for style: ScreenStatePlaceholderStyle) -> CGFloat {
        style == .compact ? compactIconSize : iconSize
    }

    static func spinnerSize(for style: ScreenStatePlaceholderStyle) -> CGFloat {
        style == .compact ? compactSpinnerSize : spinnerSize
    }
}

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
        guard
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map(\.cgColor) as CFArray,
                locations: nil
            )
        else { return }
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
    private let style: ScreenStatePlaceholderStyle

    public init(style: ScreenStatePlaceholderStyle = .standard) {
        self.style = style
        super.init(frame: .zero)
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
        ringMask.lineWidth = ScreenStatesMetrics.spinnerLineWidth
        ringMask.lineCap = .round
        ringMask.strokeStart = 0
        ringMask.strokeEnd = 0.75
        gradientRing.layer.mask = ringMask

        addSubview(gradientRing)
        let spinnerSize = ScreenStatesMetrics.spinnerSize(for: style)
        NSLayoutConstraint.activate([
            gradientRing.centerXAnchor.constraint(equalTo: centerXAnchor),
            gradientRing.centerYAnchor.constraint(equalTo: centerYAnchor),
            gradientRing.widthAnchor.constraint(equalToConstant: spinnerSize),
            gradientRing.heightAnchor.constraint(equalToConstant: spinnerSize),
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
        gradientRing.gradientLayer.colors =
            isDarkerSystemColorsEnabled
            ? [UIColor.label.cgColor, UIColor.label.cgColor]
            : [
                UIColor.systemPink.cgColor,
                UIColor.systemOrange.cgColor,
                UIColor.systemYellow.cgColor,
                UIColor.systemPink.cgColor,
            ]
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = gradientRing.bounds
        ringMask.frame = bounds
        ringMask.path =
            UIBezierPath(
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
    /// Internal (not `private`) so `@testable import` tests can verify the
    /// axis switches for compact-height (landscape iPhone) layouts — this
    /// module's test target has no live window/scene to drive a real trait
    /// collection change through.
    let stack = UIStackView()
    private let style: ScreenStatePlaceholderStyle
    private let symbol: UIImage?

    public init(
        title: String = .screenStatesNothingHere,
        systemImage: String = "tray.fill",
        style: ScreenStatePlaceholderStyle = .standard
    ) {
        self.style = style
        symbol = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: ScreenStatesMetrics.iconSize(for: style), weight: .regular)
        )
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

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.spacing = style == .compact ? 8 : 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        updateAxis()
        addSubview(stack)
        let iconSize = ScreenStatesMetrics.iconSize(for: style)
        let margin: CGFloat = style == .compact ? 12 : 24
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: margin),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -margin),
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

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass else { return }
        updateAxis()
    }

    private func updateAxis() {
        updateAxis(verticalSizeClass: traitCollection.verticalSizeClass)
    }

    /// Lays the icon beside the title, instead of above it, in a
    /// compact-height (landscape iPhone) layout — stacking them vertically
    /// there, as in the portrait-sized column this always used to assume,
    /// leaves too little height for both to fit without clipping. The
    /// `.compact` style always stays vertical regardless: a card/section's
    /// size is dictated by the card, not the device's orientation. Internal
    /// (not `private`) so tests can drive this directly — a compact-height
    /// trait collection can't be simulated without a live window/scene in
    /// this module's test target.
    func updateAxis(verticalSizeClass: UIUserInterfaceSizeClass) {
        stack.axis = (style == .standard && verticalSizeClass == .compact) ? .horizontal : .vertical
    }

    private func updateIcon() {
        updateIcon(isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// `UIAccessibility.isDarkerSystemColorsEnabled` itself is a read-only
    /// system setting that can't be toggled in a test environment.
    func updateIcon(isDarkerSystemColorsEnabled: Bool) {
        guard let symbol else { return }
        iconView.image =
            isDarkerSystemColorsEnabled
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
            forTextStyle: style == .compact ? .footnote : .body,
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
    /// Internal (not `private`) so `@testable import` tests can verify the
    /// axis switches for compact-height (landscape iPhone) layouts — this
    /// module's test target has no live window/scene to drive a real trait
    /// collection change through.
    let stack = UIStackView()
    private let textStack = UIStackView()
    private let retryButton = UIButton(configuration: .borderedTinted())
    /// Internal (not `private`) so `@testable import` tests can verify its
    /// visibility/title and simulate a tap — this module's test target
    /// has no live window/scene to drive real touch events through.
    let secondaryActionButton = UIButton(configuration: .borderless())
    private let onRetry: (() -> Void)?
    private let secondaryAction: (title: String, action: () -> Void)?
    private let style: ScreenStatePlaceholderStyle
    private let symbol: UIImage?
    private let error: Error

    /// - Parameters:
    ///   - error: the error to describe.
    ///   - onRetry: an optional retry action; shows a Retry button when given.
    ///   - secondaryAction: an optional second button shown alongside
    ///     Retry — e.g. `(title: "Go Back", action: goBack)`. Hidden by
    ///     default, so existing call sites are unaffected.
    ///   - style: the placeholder's visual style.
    public init(
        error: Error,
        onRetry: (() -> Void)? = nil,
        secondaryAction: (title: String, action: () -> Void)? = nil,
        style: ScreenStatePlaceholderStyle = .standard
    ) {
        self.error = error
        self.onRetry = onRetry
        self.secondaryAction = secondaryAction
        self.style = style
        symbol = UIImage(
            systemName: ScreenState<Never>.isConnectivityError(error) ? "wifi.exclamationmark" : "exclamationmark.triangle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: ScreenStatesMetrics.iconSize(for: style), weight: .regular)
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

        var secondaryConfiguration = UIButton.Configuration.borderless()
        secondaryConfiguration.title = secondaryAction?.title
        secondaryActionButton.configuration = secondaryConfiguration
        secondaryActionButton.addAction(UIAction { [weak self] _ in self?.secondaryAction?.action() }, for: .touchUpInside)
        secondaryActionButton.isHidden = secondaryAction == nil
        secondaryActionButton.accessibilityIdentifier = "screenStates.error.secondaryActionButton"

        textStack.addArrangedSubview(messageLabel)
        textStack.addArrangedSubview(retryButton)
        textStack.addArrangedSubview(secondaryActionButton)
        textStack.axis = .vertical
        textStack.spacing = style == .compact ? 8 : 12
        textStack.alignment = .center

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(textStack)
        stack.spacing = style == .compact ? 8 : 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        updateAxis()
        addSubview(stack)
        let iconSize = ScreenStatesMetrics.iconSize(for: style)
        let margin: CGFloat = style == .compact ? 12 : 24
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: margin),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -margin),
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

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass else { return }
        updateAxis()
    }

    private func updateAxis() {
        updateAxis(verticalSizeClass: traitCollection.verticalSizeClass)
    }

    /// Lays the icon beside the message/Retry column, instead of above it,
    /// in a compact-height (landscape iPhone) layout — stacking everything
    /// vertically there, as in the portrait-sized column this always used
    /// to assume, leaves too little height to fit without clipping. The
    /// `.compact` style always stays vertical regardless: a card/section's
    /// size is dictated by the card, not the device's orientation.
    /// Internal (not `private`) so tests can drive this directly — a
    /// compact-height trait collection can't be simulated without a live
    /// window/scene in this module's test target.
    func updateAxis(verticalSizeClass: UIUserInterfaceSizeClass) {
        stack.axis = (style == .standard && verticalSizeClass == .compact) ? .horizontal : .vertical
    }

    private func updateIcon() {
        updateIcon(isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// `UIAccessibility.isDarkerSystemColorsEnabled` itself is a read-only
    /// system setting that can't be toggled in a test environment.
    func updateIcon(isDarkerSystemColorsEnabled: Bool) {
        guard let symbol else { return }
        iconView.image =
            isDarkerSystemColorsEnabled
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
            forTextStyle: style == .compact ? .footnote : .body,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: contentSizeCategory)
        )
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        UIAccessibility.post(notification: .announcement, argument: ScreenState<Never>.error(error).accessibilityAnnouncement)
    }

    #if os(tvOS)
    /// Sends focus straight to the Retry button (when shown) instead of
    /// making the Siri Remote user hunt for it — falling back to the
    /// secondary action button if Retry isn't shown but that is.
    public override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if !retryButton.isHidden {
            return [retryButton]
        }
        if !secondaryActionButton.isHidden {
            return [secondaryActionButton]
        }
        return super.preferredFocusEnvironments
    }
    #endif
}
#endif
