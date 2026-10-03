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

    @Test("ScreenStateDefaultErrorUIView tints its icon with a colorful gradient, not a plain gray one")
    func errorUIViewIsColorful() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        #expect(containsSaturatedColor(view.iconView.image ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorUIView uses a solid tint for its icon when Increase Contrast is on")
    func errorUIViewRespectsIncreaseContrast() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        view.updateIcon(isDarkerSystemColorsEnabled: true)
        #expect(!containsSaturatedColor(view.iconView.image ?? UIImage()))
    }

    @Test("ScreenStateDefaultErrorUIView scales its message label at the largest accessibility Dynamic Type size")
    func errorUIViewScalesMessageAtLargestAccessibilitySize() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        let standardPointSize = view.messageLabel.font.pointSize

        view.updateFont(contentSizeCategory: .accessibilityExtraExtraExtraLarge)

        #expect(view.messageLabel.font.pointSize > standardPointSize)
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

    @Test("ScreenStateDefaultErrorView renders a colorful gradient icon, not a plain gray one")
    func errorViewIsColorful() {
        let image = snapshotImage(of: ScreenStateDefaultErrorView(error: SampleError()), size: CGSize(width: 300, height: 300))
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView still renders its colorful icon at the largest accessibility Dynamic Type size")
    func errorViewRendersAtLargestDynamicTypeSize() {
        // Fixed width only (like a real screen), not a fixed height too:
        // the description label grows considerably at the largest Dynamic
        // Type size, and no single fixed height reliably fits it without
        // either clipping the icon or guessing too generously.
        let renderer = ImageRenderer(content: ScreenStateDefaultErrorView(error: SampleError())
            .dynamicTypeSize(.accessibility5)
            .frame(width: 400))
        renderer.scale = 2
        #expect(containsSaturatedColor(renderer.uiImage ?? UIImage()))
    }
    #endif
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
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return false }
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
