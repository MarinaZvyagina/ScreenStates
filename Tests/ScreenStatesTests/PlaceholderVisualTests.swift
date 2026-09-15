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
/// For UIKit, this module's test target has no live window/scene to
/// render a `UIView` hierarchy into (SPM test bundles don't run inside a
/// real app shell), so instead of rendering pixels these check the
/// `CAGradientLayer` stops directly via the `internal` (not `private`)
/// `iconGradient`/`gradientRing` properties.
///
/// For SwiftUI, `ImageRenderer` *can* rasterize a view with no window, so
/// these render to a `UIImage` and assert at least one sufficiently opaque
/// pixel is clearly colorful — a cheap, environment-independent way to
/// catch a regression back to a plain gray tint, avoiding the
/// cross-Xcode-version flakiness of exact pixel-for-pixel snapshot
/// comparison against a checked-in reference image.
@Suite("Default placeholder visuals")
@MainActor
struct PlaceholderVisualTests {
    private struct SampleError: Error {}

    @Test("ScreenStateDefaultLoadingUIView tints its ring with a colorful gradient, not a plain gray spinner")
    func loadingUIViewIsColorful() {
        let view = ScreenStateDefaultLoadingUIView()
        #expect(hasSaturatedColor(view.gradientRing))
    }

    @Test("ScreenStateDefaultEmptyUIView tints its icon with a colorful gradient, not a plain gray one")
    func emptyUIViewIsColorful() {
        let view = ScreenStateDefaultEmptyUIView()
        #expect(hasSaturatedColor(view.iconGradient))
    }

    @Test("ScreenStateDefaultErrorUIView tints its icon with a colorful gradient, not a plain gray one")
    func errorUIViewIsColorful() {
        let view = ScreenStateDefaultErrorUIView(error: SampleError())
        #expect(hasSaturatedColor(view.iconGradient))
    }

    #if canImport(SwiftUI)
    @Test("ScreenStateDefaultLoadingView renders a colorful gradient, not a plain gray spinner")
    func loadingViewIsColorful() {
        let image = snapshotImage(of: ScreenStateDefaultLoadingView(), size: CGSize(width: 120, height: 120))
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultEmptyView renders a colorful gradient icon, not a plain gray one")
    func emptyViewIsColorful() {
        let image = snapshotImage(of: ScreenStateDefaultEmptyView(), size: CGSize(width: 300, height: 300))
        #expect(containsSaturatedColor(image))
    }

    @Test("ScreenStateDefaultErrorView renders a colorful gradient icon, not a plain gray one")
    func errorViewIsColorful() {
        let image = snapshotImage(of: ScreenStateDefaultErrorView(error: SampleError()), size: CGSize(width: 300, height: 300))
        #expect(containsSaturatedColor(image))
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

// MARK: - SwiftUI rendering

#if canImport(SwiftUI)
@MainActor
private func snapshotImage<V: View>(of view: V, size: CGSize) -> UIImage {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = 2
    return renderer.uiImage ?? UIImage()
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
#endif
