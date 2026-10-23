// UIImage (used for both the UIKit structural checks and the SwiftUI
// ImageRenderer-based pixel checks below) only exists where UIKit does —
// on macOS, ImageRenderer exposes .nsImage instead, and there's no
// UIActivityIndicatorView-style UIKit surface to test structurally either.
#if canImport(UIKit) && !os(watchOS)
import Foundation
import Testing
import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import ScreenStates

/// Regression tests protecting the default placeholders' gradient
/// treatment.
///
/// The Empty/Error UIKit icons are pre-rendered `UIImage`s (see
/// `gradientTintedImage` in `UIKitDefaultStateViews.swift`), reachable via
/// the `internal` (not `private`) `iconView` property, so they're checked
/// the same way as the SwiftUI renders: at least one sufficiently opaque
/// pixel must be clearly colorful — a cheap, environment-independent way to
/// catch a regression back to a plain gray tint, avoiding the
/// cross-Xcode-version flakiness of exact pixel-for-pixel snapshot
/// comparison against a checked-in reference image. The Loading UIKit ring
/// still animates via a live `CAGradientLayer` with no static bitmap to
/// inspect, so it's checked structurally via `gradientRing`'s gradient
/// stops instead.
@Suite("Default placeholder visuals")
@MainActor
struct PlaceholderVisualTests {
    private struct SampleError: Error {}
    private struct SampleDisplayableError: ScreenStateDisplayableError {
        let displayMessage: String
    }

    @Test("ScreenStateDefaultLoadingUIView tints its ring with a colorful gradient, not a plain gray spinner")
    func loadingUIViewIsColorful() {
        let view = ScreenStateDefaultLoadingUIView()
        #expect(hasSaturatedColor(view.gradientRing))
    }

    @Test("ScreenStateDefaultLoadingUIView animates its ring by default")
    func loadingUIViewAnimatesByDefault() {
        let view = ScreenStateDefaultLoadingUIView()
        #expect(view.gradientRing.layer.animation(forKey: "rotation") != nil)
    }

    @Test("ScreenStateDefaultLoadingUIView removes its spin animation when Reduce Motion is on")
    func loadingUIViewRespectsReduceMotion() {
        let view = ScreenStateDefaultLoadingUIView()
        view.updateRotation(reduceMotion: true)
        #expect(view.gradientRing.layer.animation(forKey: "rotation") == nil)
    }

    @Test("ScreenStateDefaultLoadingUIView re-adds its spin animation once Reduce Motion turns back off")
    func loadingUIViewReAddsAnimationWhenReduceMotionTurnsOff() {
        let view = ScreenStateDefaultLoadingUIView()
        view.updateRotation(reduceMotion: true)
        view.updateRotation(reduceMotion: false)
        #expect(view.gradientRing.layer.animation(forKey: "rotation") != nil)
    }

    @Test("ScreenStateDefaultLoadingUIView uses a solid tint for its ring when Increase Contrast is on")
    func loadingUIViewRespectsIncreaseContrast() {
        let view = ScreenStateDefaultLoadingUIView()
        view.updateGradientColors(isDarkerSystemColorsEnabled: true)
        #expect(!hasSaturatedColor(view.gradientRing))
    }

    @Test("ScreenStateDefaultLoadingUIView restores its colorful gradient once Increase Contrast turns back off")
    func loadingUIViewRestoresGradientWhenIncreaseContrastTurnsOff() {
        let view = ScreenStateDefaultLoadingUIView()
        view.updateGradientColors(isDarkerSystemColorsEnabled: true)
        view.updateGradientColors(isDarkerSystemColorsEnabled: false)
        #expect(hasSaturatedColor(view.gradientRing))
    }

    @Test("ScreenStateDefaultLoadingUIView still renders its colorful ring at the largest accessibility Dynamic Type size")
    func loadingUIViewRendersAtLargestAccessibilitySize() {
        var view: ScreenStateDefaultLoadingUIView?
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge).performAsCurrent {
            view = ScreenStateDefaultLoadingUIView()
        }
        #expect(hasSaturatedColor(view!.gradientRing))
    }

    @Test("ScreenStateDefaultLoadingUIView sizes its ring down for the .compact style")
    func loadingUIViewCompactStyleShrinksRing() {
        let standard = ScreenStateDefaultLoadingUIView(style: .standard)
        let compact = ScreenStateDefaultLoadingUIView(style: .compact)
        #expect(widthConstraintConstant(of: standard.gradientRing)! > widthConstraintConstant(of: compact.gradientRing)!)
    }

    @Test("ScreenStateDefaultEmptyUIView tints its icon with a colorful gradient, not a plain gray one")
    func emptyUIViewIsColorful() {
        let view = ScreenStateDefaultEmptyUIView()
        #expect(containsSaturatedColor(view.iconView.image ?? UIImage()))
    }

    @Test("ScreenStateDefaultEmptyUIView uses a solid tint for its icon when Increase Contrast is on")
    func emptyUIViewRespectsIncreaseContrast() {
        let view = ScreenStateDefaultEmptyUIView()
        view.updateIcon(isDarkerSystemColorsEnabled: true)
        #expect(!containsSaturatedColor(view.iconView.image ?? UIImage()))
    }

    @Test("ScreenStateDefaultEmptyUIView scales its title label at the largest accessibility Dynamic Type size")
    func emptyUIViewScalesTitleAtLargestAccessibilitySize() {
        let view = ScreenStateDefaultEmptyUIView()
        let standardPointSize = view.titleLabel.font.pointSize

        view.updateFont(contentSizeCategory: .accessibilityExtraExtraExtraLarge)

        #expect(view.titleLabel.font.pointSize > standardPointSize)
    }

    @Test("ScreenStateDefaultEmptyUIView lays its icon beside the title in a compact-height (landscape iPhone) layout")
    func emptyUIViewUsesHorizontalAxisForCompactHeight() {
        let view = ScreenStateDefaultEmptyUIView()
        view.updateAxis(verticalSizeClass: .compact)
        #expect(view.stack.axis == .horizontal)
    }

    @Test("ScreenStateDefaultEmptyUIView stacks its icon above the title in a regular-height layout")
    func emptyUIViewUsesVerticalAxisForRegularHeight() {
        let view = ScreenStateDefaultEmptyUIView()
        view.updateAxis(verticalSizeClass: .compact)
        view.updateAxis(verticalSizeClass: .regular)
        #expect(view.stack.axis == .vertical)
    }

    @Test("ScreenStateDefaultEmptyUIView sizes its icon down for the .compact style")
    func emptyUIViewCompactStyleShrinksIcon() {
        let standard = ScreenStateDefaultEmptyUIView(style: .standard)
        let compact = ScreenStateDefaultEmptyUIView(style: .compact)
        #expect(widthConstraintConstant(of: standard.iconView)! > widthConstraintConstant(of: compact.iconView)!)
    }

    @Test("ScreenStateDefaultEmptyUIView uses a smaller font for the .compact style")
    func emptyUIViewCompactStyleShrinksFont() {
        let standard = ScreenStateDefaultEmptyUIView(style: .standard)
        let compact = ScreenStateDefaultEmptyUIView(style: .compact)
        #expect(compact.titleLabel.font.pointSize < standard.titleLabel.font.pointSize)
    }

    @Test("ScreenStateDefaultEmptyUIView keeps a vertical axis for the .compact style even in a compact-height layout")
    func emptyUIViewCompactStyleStaysVerticalInCompactHeight() {
        let view = ScreenStateDefaultEmptyUIView(style: .compact)
        view.updateAxis(verticalSizeClass: .compact)
        #expect(view.stack.axis == .vertical)
    }

    @Test("ScreenStateDefaultErrorUIView tints its icon with a colorful gradient, not a plain gray one")
    func errorUIViewIsColorful() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        #expect(containsSaturatedColor(view.iconView.image ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorUIView still renders a colorful icon for a connectivity URLError")
    func errorUIViewIsColorfulForConnectivityError() {
        let view = ScreenStateDefaultErrorUIView(error: URLError(.notConnectedToInternet))
        #expect(containsSaturatedColor(view.iconView.image ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorUIView still renders a colorful icon for a connectivity URLError at the largest accessibility Dynamic Type size")
    func errorUIViewIsColorfulForConnectivityErrorAtLargestDynamicTypeSize() {
        let view = ScreenStateDefaultErrorUIView(error: URLError(.notConnectedToInternet))
        view.updateFont(contentSizeCategory: .accessibilityExtraExtraExtraLarge)
        #expect(containsSaturatedColor(view.iconView.image ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorUIView hides its secondary action button by default")
    func errorUIViewHidesSecondaryActionButtonByDefault() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        #expect(view.secondaryActionButton.isHidden)
    }

    @Test("ScreenStateDefaultErrorUIView shows its secondary action button with the given title when provided")
    func errorUIViewShowsSecondaryActionButtonWhenProvided() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError(), secondaryAction: (title: "Go Back", action: {}))
        #expect(!view.secondaryActionButton.isHidden)
        #expect(view.secondaryActionButton.configuration?.title == "Go Back")
    }

    @Test("ScreenStateDefaultErrorUIView's secondary action button invokes the given action")
    func errorUIViewSecondaryActionButtonInvokesAction() {
        var tapped = false
        let view = ScreenStateDefaultErrorUIView(error: SampleError(), secondaryAction: (title: "Go Back", action: { tapped = true }))

        view.secondaryActionButton.sendActions(for: .touchUpInside)

        #expect(tapped)
    }

    @Test("ScreenStateDefaultErrorUIView uses a solid tint for its icon when Increase Contrast is on")
    func errorUIViewRespectsIncreaseContrast() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        view.updateIcon(isDarkerSystemColorsEnabled: true)
        #expect(!containsSaturatedColor(view.iconView.image ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorUIView shows a ScreenStateDisplayableError's displayMessage instead of localizedDescription")
    func errorUIViewShowsDisplayMessageForDisplayableError() {
        let view = ScreenStateDefaultErrorUIView(error: SampleDisplayableError(displayMessage: "That article was removed."))
        #expect(view.messageLabel.text == "That article was removed.")
    }

    @Test("ScreenStateDefaultErrorUIView scales its message label at the largest accessibility Dynamic Type size")
    func errorUIViewScalesMessageAtLargestAccessibilitySize() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        let standardPointSize = view.messageLabel.font.pointSize

        view.updateFont(contentSizeCategory: .accessibilityExtraExtraExtraLarge)

        #expect(view.messageLabel.font.pointSize > standardPointSize)
    }

    @Test("ScreenStateDefaultErrorUIView lays its icon beside the message/Retry column in a compact-height (landscape iPhone) layout")
    func errorUIViewUsesHorizontalAxisForCompactHeight() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        view.updateAxis(verticalSizeClass: .compact)
        #expect(view.stack.axis == .horizontal)
    }

    @Test("ScreenStateDefaultErrorUIView stacks its icon above the message/Retry column in a regular-height layout")
    func errorUIViewUsesVerticalAxisForRegularHeight() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        view.updateAxis(verticalSizeClass: .compact)
        view.updateAxis(verticalSizeClass: .regular)
        #expect(view.stack.axis == .vertical)
    }

    @Test("ScreenStateDefaultErrorUIView sizes its icon down for the .compact style")
    func errorUIViewCompactStyleShrinksIcon() {
        let standard = ScreenStateDefaultErrorUIView(error: SampleError(), style: .standard)
        let compact = ScreenStateDefaultErrorUIView(error: SampleError(), style: .compact)
        #expect(widthConstraintConstant(of: standard.iconView)! > widthConstraintConstant(of: compact.iconView)!)
    }

    @Test("ScreenStateDefaultErrorUIView uses a smaller font for the .compact style")
    func errorUIViewCompactStyleShrinksFont() {
        let standard = ScreenStateDefaultErrorUIView(error: SampleError(), style: .standard)
        let compact = ScreenStateDefaultErrorUIView(error: SampleError(), style: .compact)
        #expect(compact.messageLabel.font.pointSize < standard.messageLabel.font.pointSize)
    }

    @Test("ScreenStateDefaultErrorUIView keeps a vertical axis for the .compact style even in a compact-height layout")
    func errorUIViewCompactStyleStaysVerticalInCompactHeight() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError(), style: .compact)
        view.updateAxis(verticalSizeClass: .compact)
        #expect(view.stack.axis == .vertical)
    }

    @Test("ScreenStateShimmerLoadingUIView pulses by default")
    func shimmerLoadingUIViewPulsesByDefault() {
        let view = ScreenStateShimmerLoadingUIView()
        #expect(view.skeletonStack.layer.animation(forKey: "shimmerPulse") != nil)
    }

    @Test("ScreenStateShimmerLoadingUIView removes its pulse animation when Reduce Motion is on")
    func shimmerLoadingUIViewRespectsReduceMotion() {
        let view = ScreenStateShimmerLoadingUIView()
        view.updatePulse(reduceMotion: true)
        #expect(view.skeletonStack.layer.animation(forKey: "shimmerPulse") == nil)
    }

    @Test("ScreenStateShimmerLoadingUIView re-adds its pulse animation once Reduce Motion turns back off")
    func shimmerLoadingUIViewReAddsAnimationWhenReduceMotionTurnsOff() {
        let view = ScreenStateShimmerLoadingUIView()
        view.updatePulse(reduceMotion: true)
        view.updatePulse(reduceMotion: false)
        #expect(view.skeletonStack.layer.animation(forKey: "shimmerPulse") != nil)
    }

    @Test("ScreenStateShimmerLoadingUIView uses a more visible gray fill when Increase Contrast is on")
    func shimmerLoadingUIViewRespectsIncreaseContrast() {
        let view = ScreenStateShimmerLoadingUIView()
        view.updateFillColor(isDarkerSystemColorsEnabled: true)
        #expect(view.avatar.backgroundColor == .systemGray)
    }

    @Test("ScreenStateShimmerLoadingUIView restores its low-contrast fill once Increase Contrast turns back off")
    func shimmerLoadingUIViewRestoresFillWhenIncreaseContrastTurnsOff() {
        let view = ScreenStateShimmerLoadingUIView()
        view.updateFillColor(isDarkerSystemColorsEnabled: true)
        view.updateFillColor(isDarkerSystemColorsEnabled: false)
        #expect(view.avatar.backgroundColor == .tertiarySystemFill)
    }

    #if canImport(SwiftUI)
    @Test("ScreenStateDefaultLoadingView renders a colorful gradient, not a plain gray spinner")
    func loadingViewIsColorful() {
        let image = snapshotImage(of: ScreenStateDefaultLoadingView(), size: CGSize(width: 120, height: 120))
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultLoadingView still renders its colorful ring at the largest accessibility Dynamic Type size")
    func loadingViewRendersAtLargestDynamicTypeSize() {
        let image = snapshotImage(
            of: ScreenStateDefaultLoadingView().dynamicTypeSize(.accessibility5),
            size: CGSize(width: 120, height: 120)
        )
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultLoadingView still renders its colorful ring in the .compact style, sized for a card rather than a whole screen")
    func loadingViewRendersInCompactStyle() {
        let image = snapshotImage(of: ScreenStateDefaultLoadingView(style: .compact), size: CGSize(width: 80, height: 80))
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStatesTheme.standard has no overrides")
    func themeStandardHasNoOverrides() {
        #expect(ScreenStatesTheme.standard == ScreenStatesTheme())
        #expect(ScreenStatesTheme.standard.tint == nil)
        #expect(ScreenStatesTheme.standard.titleFont == nil)
        #expect(ScreenStatesTheme.standard.messageFont == nil)
    }

    @Test("ScreenStateDefaultLoadingView uses the theme's tint instead of its gradient, when set")
    func loadingViewUsesThemeTint() {
        let image = snapshotImage(
            of: ScreenStateDefaultLoadingView().screenStatesTheme(ScreenStatesTheme(tint: Color(red: 0, green: 1, blue: 0))),
            size: CGSize(width: 120, height: 120)
        )
        #expect(containsPixelMatching(image, target: (0, 255, 0)))
    }

    @Test("ScreenStateDefaultEmptyView renders a colorful gradient icon, not a plain gray one")
    func emptyViewIsColorful() {
        let image = snapshotImage(of: ScreenStateDefaultEmptyView(), size: CGSize(width: 300, height: 300))
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultEmptyView still renders its colorful icon at the largest accessibility Dynamic Type size")
    func emptyViewRendersAtLargestDynamicTypeSize() {
        let image = snapshotImage(
            of: ScreenStateDefaultEmptyView().dynamicTypeSize(.accessibility5),
            size: CGSize(width: 400, height: 600)
        )
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultEmptyView uses the theme's tint instead of its gradient, when set")
    func emptyViewUsesThemeTint() {
        let image = snapshotImage(
            of: ScreenStateDefaultEmptyView().screenStatesTheme(ScreenStatesTheme(tint: Color(red: 0, green: 1, blue: 0))),
            size: CGSize(width: 300, height: 300)
        )
        #expect(containsPixelMatching(image, target: (0, 255, 0)))
    }

    @Test("ScreenStateDefaultEmptyView still renders when a theme titleFont is set")
    func emptyViewRendersWithThemeFont() {
        let image = snapshotImage(
            of: ScreenStateDefaultEmptyView().screenStatesTheme(ScreenStatesTheme(titleFont: .largeTitle)),
            size: CGSize(width: 300, height: 300)
        )
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView renders a colorful gradient icon, not a plain gray one")
    func errorViewIsColorful() {
        let image = snapshotImage(of: ScreenStateDefaultErrorView(error: SampleError()), size: CGSize(width: 300, height: 300))
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView still renders a colorful icon for a connectivity URLError")
    func errorViewIsColorfulForConnectivityError() {
        let image = snapshotImage(
            of: ScreenStateDefaultErrorView(error: URLError(.notConnectedToInternet)),
            size: CGSize(width: 300, height: 300)
        )
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView still renders a colorful icon for a connectivity URLError at the largest accessibility Dynamic Type size")
    func errorViewIsColorfulForConnectivityErrorAtLargestDynamicTypeSize() {
        // Fixed width only, same reason as the generic largest-Dynamic-Type
        // test above.
        let renderer = ImageRenderer(
            content: ScreenStateDefaultErrorView(error: URLError(.notConnectedToInternet))
                .dynamicTypeSize(.accessibility5)
                .frame(width: 400))
        renderer.scale = 2
        #expect(containsSaturatedColor(renderer.uiImage ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorView still renders its colorful icon with a secondary action alongside Retry")
    func errorViewRendersWithSecondaryAction() {
        // Fixed width only (as in the largest-Dynamic-Type-size test
        // above): two stacked buttons grow the actions area taller than a
        // fixed 300x300 frame reliably fits alongside the icon.
        let renderer = ImageRenderer(
            content: ScreenStateDefaultErrorView(
                error: SampleError(),
                onRetry: {},
                secondaryAction: (title: "Go Back", action: {})
            )
            .frame(width: 300))
        renderer.scale = 2
        #expect(containsSaturatedColor(renderer.uiImage ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorView still renders its colorful icon with only a secondary action, no Retry")
    func errorViewRendersWithOnlySecondaryAction() {
        let renderer = ImageRenderer(
            content: ScreenStateDefaultErrorView(error: SampleError(), secondaryAction: (title: "Go Back", action: {}))
                .frame(width: 300))
        renderer.scale = 2
        #expect(containsSaturatedColor(renderer.uiImage ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorView uses the theme's tint instead of its gradient, when set")
    func errorViewUsesThemeTint() {
        let image = snapshotImage(
            of: ScreenStateDefaultErrorView(error: SampleError())
                .screenStatesTheme(ScreenStatesTheme(tint: Color(red: 0, green: 1, blue: 0))),
            size: CGSize(width: 300, height: 300)
        )
        #expect(containsPixelMatching(image, target: (0, 255, 0)))
    }

    @Test("ScreenStateDefaultErrorView still renders when a theme messageFont is set")
    func errorViewRendersWithThemeFont() {
        // Fixed width only (as in the largest-Dynamic-Type-size test
        // above): a `.largeTitle` description can grow tall enough that a
        // fixed height would clip the icon out of the captured frame.
        let renderer = ImageRenderer(
            content: ScreenStateDefaultErrorView(error: SampleError())
                .screenStatesTheme(ScreenStatesTheme(messageFont: .largeTitle))
                .frame(width: 400))
        renderer.scale = 2
        #expect(containsSaturatedColor(renderer.uiImage ?? UIImage()))
    }

    @Test("ScreenStateDefaultEmptyView still renders its colorful icon in the .compact style, sized for a card rather than a whole screen")
    func emptyViewRendersInCompactStyle() {
        let image = snapshotImage(of: ScreenStateDefaultEmptyView(style: .compact), size: CGSize(width: 200, height: 80))
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView still renders its colorful icon in the .compact style, sized for a card rather than a whole screen")
    func errorViewRendersInCompactStyle() {
        let image = snapshotImage(
            of: ScreenStateDefaultErrorView(error: SampleError(), style: .compact),
            size: CGSize(width: 280, height: 80)
        )
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView still renders its colorful icon at the largest accessibility Dynamic Type size")
    func errorViewRendersAtLargestDynamicTypeSize() {
        // Fixed width only (like a real screen), not a fixed height too:
        // the description label grows considerably at the largest Dynamic
        // Type size, and no single fixed height reliably fits it without
        // either clipping the icon or guessing too generously.
        let renderer = ImageRenderer(
            content: ScreenStateDefaultErrorView(error: SampleError())
                .dynamicTypeSize(.accessibility5)
                .frame(width: 400))
        renderer.scale = 2
        #expect(containsSaturatedColor(renderer.uiImage ?? UIImage()))
    }

    @Test("ScreenStateShimmerLoadingView renders its skeleton shapes, not a blank view")
    func shimmerLoadingViewRendersContent() {
        let image = snapshotImage(of: ScreenStateShimmerLoadingView(), size: CGSize(width: 240, height: 80))
        #expect(containsNonTransparentPixel(image))
    }

    @Test("ScreenStateShimmerLoadingView still renders its skeleton shapes at the largest accessibility Dynamic Type size")
    func shimmerLoadingViewRendersAtLargestDynamicTypeSize() {
        let image = snapshotImage(
            of: ScreenStateShimmerLoadingView().dynamicTypeSize(.accessibility5),
            size: CGSize(width: 240, height: 80)
        )
        #expect(containsNonTransparentPixel(image))
    }

    @Test("ScreenStateShimmerLoadingView still renders its skeleton shapes when a theme tint is set")
    func shimmerLoadingViewRendersWithThemeTint() {
        // The skeleton fill is intentionally translucent (`tint.opacity(_:)`),
        // so this checks the tinted code path doesn't crash or blank the
        // render rather than color-matching a premultiplied, partially
        // transparent pixel.
        let image = snapshotImage(
            of: ScreenStateShimmerLoadingView().screenStatesTheme(ScreenStatesTheme(tint: Color(red: 0, green: 1, blue: 0))),
            size: CGSize(width: 240, height: 80)
        )
        #expect(containsNonTransparentPixel(image))
    }

    @Test("ScreenStateRedactedLoadingView renders its redacted content, not a blank view")
    func redactedLoadingViewRendersContent() {
        let image = snapshotImage(
            of: ScreenStateRedactedLoadingView {
                Text("Sample Title")
                    .font(.headline)
                    .foregroundStyle(Color(red: 1, green: 0, blue: 0))
            },
            size: CGSize(width: 240, height: 40)
        )
        #expect(containsNonTransparentPixel(image))
    }

    @Test("ScreenStateRedactedLoadingView redacts its content instead of showing it as-is")
    func redactedLoadingViewRedactsContent() {
        // `.redacted(reason: .placeholder)` replaces text glyphs with a
        // solid shape and desaturates custom colors, so a vivid red
        // "loaded" rendering of the same content should not survive
        // through the placeholder.
        let plain = snapshotImage(
            of: Text("Sample Title").font(.headline).foregroundStyle(Color(red: 1, green: 0, blue: 0)),
            size: CGSize(width: 240, height: 40)
        )
        let redacted = snapshotImage(
            of: ScreenStateRedactedLoadingView {
                Text("Sample Title")
                    .font(.headline)
                    .foregroundStyle(Color(red: 1, green: 0, blue: 0))
            },
            size: CGSize(width: 240, height: 40)
        )
        #expect(containsPixelMatching(plain, target: (255, 0, 0), tolerance: 40))
        #expect(!containsPixelMatching(redacted, target: (255, 0, 0), tolerance: 40))
    }

    #if os(iOS)
    @Test("ScreenStateDefaultEmptyView still renders its colorful icon in a compact-height (landscape iPhone) layout")
    func emptyViewRendersInCompactHeightLayout() {
        let image = snapshotImage(
            of: ScreenStateDefaultEmptyView().environment(\.verticalSizeClass, .compact),
            size: CGSize(width: 480, height: 180)
        )
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView still renders its colorful icon in a compact-height (landscape iPhone) layout")
    func errorViewRendersInCompactHeightLayout() {
        let image = snapshotImage(
            of: ScreenStateDefaultErrorView(error: SampleError()).environment(\.verticalSizeClass, .compact),
            size: CGSize(width: 480, height: 180)
        )
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultEmptyView still renders its colorful icon in a compact-height layout at the largest accessibility Dynamic Type size")
    func emptyViewRendersInCompactHeightAtLargestDynamicTypeSize() {
        let image = snapshotImage(
            of: ScreenStateDefaultEmptyView()
                .environment(\.verticalSizeClass, .compact)
                .dynamicTypeSize(.accessibility5),
            size: CGSize(width: 480, height: 180)
        )
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView still renders its colorful icon in a compact-height layout at the largest accessibility Dynamic Type size")
    func errorViewRendersInCompactHeightAtLargestDynamicTypeSize() {
        let image = snapshotImage(
            of: ScreenStateDefaultErrorView(error: SampleError())
                .environment(\.verticalSizeClass, .compact)
                .dynamicTypeSize(.accessibility5),
            size: CGSize(width: 480, height: 180)
        )
        #expect(containsSaturatedColor(image))
    }
    #endif
    #endif
}

// MARK: - UIKit layout inspection

/// The `.constant` of `view`'s own fixed-width constraint (as activated via
/// `view.widthAnchor.constraint(equalToConstant:)`), or `nil` if it has
/// none — used to verify `.compact`-style views size their icon/ring down
/// without needing a live window to lay out and measure.
private func widthConstraintConstant(of view: UIView) -> CGFloat? {
    view.constraints.first { $0.firstAttribute == .width }?.constant
}

// MARK: - UIKit gradient inspection

/// `true` if `gradientView`'s gradient stops include at least one clearly
/// colorful (non-grayscale) color.
private func hasSaturatedColor(_ gradientView: GradientUIView, threshold: CGFloat = 40) -> Bool {
    let colors = gradientView.gradientLayer.colors as? [CGColor] ?? []
    return colors.contains { isSaturated($0, threshold: threshold) }
}

private func isSaturated(_ cgColor: CGColor, threshold: CGFloat) -> Bool {
    guard let components = cgColor.components, components.count >= 3 else { return false }
    let r = components[0] * 255
    let g = components[1] * 255
    let b = components[2] * 255
    return max(r, g, b) - min(r, g, b) > threshold
}

/// `true` if any sufficiently opaque pixel in `image` is clearly colorful
/// (its channels diverge by more than `threshold`) rather than grayscale.
private func containsSaturatedColor(_ image: UIImage, threshold: CGFloat = 40) -> Bool {
    guard let cgImage = image.cgImage else { return false }
    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0 else { return false }

    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard
        let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else { return false }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    for pixelIndex in stride(from: 0, to: pixels.count, by: 4) {
        guard pixels[pixelIndex + 3] > 200 else { continue }
        let r = CGFloat(pixels[pixelIndex])
        let g = CGFloat(pixels[pixelIndex + 1])
        let b = CGFloat(pixels[pixelIndex + 2])
        if max(r, g, b) - min(r, g, b) > threshold {
            return true
        }
    }
    return false
}

/// `true` if any sufficiently opaque pixel in `image` is close to `target`
/// (each channel within `tolerance`) — used to verify a theme's solid
/// `tint` actually replaces the default gradient, rather than just
/// checking for "some colorful pixel" the way `containsSaturatedColor`
/// does (which a still-gradient render would also satisfy).
private func containsPixelMatching(_ image: UIImage, target: (r: CGFloat, g: CGFloat, b: CGFloat), tolerance: CGFloat = 30) -> Bool {
    guard let cgImage = image.cgImage else { return false }
    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0 else { return false }

    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard
        let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else { return false }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    for pixelIndex in stride(from: 0, to: pixels.count, by: 4) {
        guard pixels[pixelIndex + 3] > 200 else { continue }
        let r = CGFloat(pixels[pixelIndex])
        let g = CGFloat(pixels[pixelIndex + 1])
        let b = CGFloat(pixels[pixelIndex + 2])
        if abs(r - target.r) < tolerance, abs(g - target.g) < tolerance, abs(b - target.b) < tolerance {
            return true
        }
    }
    return false
}

/// `true` if any pixel in `image` is more than barely transparent — a
/// cheap regression guard against a totally blank render, for placeholders
/// (like the shimmer skeleton) whose fill is intentionally grayscale and
/// semi-transparent, so `containsSaturatedColor`'s colorfulness/opacity
/// thresholds don't apply.
private func containsNonTransparentPixel(_ image: UIImage, alphaThreshold: CGFloat = 10) -> Bool {
    guard let cgImage = image.cgImage else { return false }
    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0 else { return false }

    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard
        let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else { return false }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    for pixelIndex in stride(from: 0, to: pixels.count, by: 4) where CGFloat(pixels[pixelIndex + 3]) > alphaThreshold {
        return true
    }
    return false
}

// MARK: - SwiftUI rendering

#if canImport(SwiftUI)
@MainActor
private func snapshotImage<V: View>(of view: V, size: CGSize) -> UIImage {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = 2
    return renderer.uiImage ?? UIImage()
}
#endif
#endif
