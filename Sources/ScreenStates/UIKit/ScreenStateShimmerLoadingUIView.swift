#if canImport(UIKit) && !os(watchOS)
import UIKit

/// An alternative Loading placeholder: a pulsing skeleton of a circular
/// avatar plus two text-line placeholders, instead of a spinner. Opt-in —
/// ``ScreenStateDefaultLoadingUIView`` is still what every default-wired
/// `ScreenStateContainerView`/`ScreenStateViewController` shows; pass this
/// one explicitly wherever a `loadingView`-shaped placeholder is expected.
public final class ScreenStateShimmerLoadingUIView: UIView {
    /// Internal (not `private`) so `@testable import` tests can verify the
    /// pulse animation and fill color without any rendering — this
    /// module's test target has no live window/scene to snapshot a real
    /// render into.
    let skeletonStack = UIStackView()
    let avatar = UIView()
    private let line1 = UIView()
    private let line2 = UIView()

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
        accessibilityIdentifier = "screenStates.shimmerLoading"
        isAccessibilityElement = true
        accessibilityLabel = .screenStatesLoading

        [avatar, line1, line2].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        avatar.layer.cornerRadius = 24
        line1.layer.cornerRadius = 4
        line2.layer.cornerRadius = 4

        let lines = UIStackView(arrangedSubviews: [line1, line2])
        lines.axis = .vertical
        lines.spacing = 8
        lines.alignment = .leading

        skeletonStack.addArrangedSubview(avatar)
        skeletonStack.addArrangedSubview(lines)
        skeletonStack.axis = .horizontal
        skeletonStack.spacing = 12
        skeletonStack.alignment = .center
        skeletonStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skeletonStack)

        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 48),
            avatar.heightAnchor.constraint(equalToConstant: 48),
            line1.widthAnchor.constraint(equalToConstant: 160),
            line1.heightAnchor.constraint(equalToConstant: 14),
            line2.widthAnchor.constraint(equalToConstant: 100),
            line2.heightAnchor.constraint(equalToConstant: 14),
            skeletonStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            skeletonStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            skeletonStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            skeletonStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])

        updateFillColor()
        updatePulse()
    }

    /// Adds the pulse animation, unless Reduce Motion is on, in which case
    /// the animation is removed instead and the skeleton stays at a fixed
    /// partial opacity. Also called when Reduce Motion is toggled live, so
    /// an already-visible skeleton responds immediately instead of only on
    /// the next appearance.
    @objc
    private func reduceMotionStatusDidChange() {
        updatePulse()
    }

    private func updatePulse() {
        updatePulse(reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// `UIAccessibility.isReduceMotionEnabled` itself is a read-only system
    /// setting that can't be toggled in a test environment.
    func updatePulse(reduceMotion: Bool) {
        guard !reduceMotion else {
            skeletonStack.layer.removeAnimation(forKey: "shimmerPulse")
            skeletonStack.layer.opacity = 0.7
            return
        }
        skeletonStack.layer.opacity = 1
        guard skeletonStack.layer.animation(forKey: "shimmerPulse") == nil else { return }
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1
        pulse.toValue = 0.4
        pulse.duration = 1
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        skeletonStack.layer.add(pulse, forKey: "shimmerPulse")
    }

    /// Swaps the skeleton's fill for a more visible gray when Increase
    /// Contrast is on. Also called when Increase Contrast is toggled live,
    /// so an already-visible skeleton responds immediately instead of only
    /// on the next appearance.
    @objc
    private func darkerSystemColorsStatusDidChange() {
        updateFillColor()
    }

    private func updateFillColor() {
        updateFillColor(isDarkerSystemColorsEnabled: UIAccessibility.isDarkerSystemColorsEnabled)
    }

    /// Internal (not `private`) so tests can drive this directly --
    /// `UIAccessibility.isDarkerSystemColorsEnabled` itself is a read-only
    /// system setting that can't be toggled in a test environment.
    func updateFillColor(isDarkerSystemColorsEnabled: Bool) {
        let color: UIColor = isDarkerSystemColorsEnabled ? .systemGray : .tertiarySystemFill
        [avatar, line1, line2].forEach { $0.backgroundColor = color }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        UIAccessibility.post(notification: .announcement, argument: String.screenStatesLoading)
    }
}
#endif
