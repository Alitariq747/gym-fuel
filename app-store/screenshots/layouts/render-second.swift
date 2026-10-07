import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = URL(fileURLWithPath: "/Users/ahmadalitariq/Downloads/circa_actual screens/Screenshot 2026-10-07 at 6.38.12\u{202F}PM.png")
let outputURL = root.appendingPathComponent("app-store/screenshots/en-US/02-meal-breakdown.png")
let width = 1290, height = 2796
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                        bytesPerRow: width * 4, space: space,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}
func rect(_ x: CGFloat, _ top: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: CGFloat(height) - top - h, width: w, height: h)
}
let gradient = CGGradient(colorsSpace: space,
                          colors: [color(0xFBFAF6).cgColor, color(0xF4F1E8).cgColor] as CFArray,
                          locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: .zero, options: [])
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
let font = NSFont.systemFont(ofSize: 100, weight: .semibold)
for (line, top, ink) in [("See what went", CGFloat(133), UInt32(0x1A1917)),
                         ("into your meal.", CGFloat(256), UInt32(0x8F6420))] {
    let text = NSAttributedString(string: line, attributes: [.font: font, .foregroundColor: color(ink), .kern: -2.5])
    precondition(text.size().width <= 710, "Headline overlaps photo")
    text.draw(at: CGPoint(x: 72, y: CGFloat(height) - top - text.size().height))
}
let subtitle = NSAttributedString(
    string: "Estimated ingredients, portions and nutrition.",
    attributes: [.font: NSFont.systemFont(ofSize: 38), .foregroundColor: color(0x56534C)]
)
precondition(subtitle.size().width <= 1146, "Subtitle overflow")
subtitle.draw(at: CGPoint(x: 72, y: CGFloat(height) - 424 - subtitle.size().height))
NSGraphicsContext.restoreGraphicsState()

let photoURL = URL(fileURLWithPath: "/Users/ahmadalitariq/Downloads/circa_actual screens/Screenshot 2026-10-07 at 6.37.44\u{202F}PM.png")
let photoSource = CGImageSourceCreateWithURL(photoURL as CFURL, nil)!
let photoCapture = CGImageSourceCreateImageAtIndex(photoSource, 0, nil)!
// Use the actual photograph, excluding the app's blurred letterboxing.
let photoCrop = photoCapture.cropping(to: CGRect(x: 264, y: 486, width: 762, height: 510))!
// Trace the original plate rim so the marketing cutout retains the source pixels.
let photoScale: CGFloat = 1.17
let photoRect = rect(716, -41, 762 * photoScale, 510 * photoScale)
func platePoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: photoRect.minX + x * photoScale, y: photoRect.maxY - y * photoScale)
}
let photoOutline = CGMutablePath()
photoOutline.move(to: platePoint(410, 80))
photoOutline.addCurve(to: platePoint(669, 247), control1: platePoint(553, 82), control2: platePoint(661, 143))
photoOutline.addCurve(to: platePoint(403, 437), control1: platePoint(689, 349), control2: platePoint(553, 425))
photoOutline.addCurve(to: platePoint(113, 266), control1: platePoint(250, 445), control2: platePoint(111, 371))
photoOutline.addCurve(to: platePoint(278, 99), control1: platePoint(110, 192), control2: platePoint(179, 130))
photoOutline.addCurve(to: platePoint(410, 80), control1: platePoint(324, 85), control2: platePoint(371, 77))
photoOutline.closeSubpath()
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -19), blur: 32,
                  color: color(0x41331C).withAlphaComponent(0.26).cgColor)
context.addPath(photoOutline)
context.setFillColor(color(0xEAE6DA).cgColor)
context.fillPath()
context.restoreGState()
context.saveGState()
context.addPath(photoOutline)
context.clip()
context.interpolationQuality = .high
context.draw(photoCrop, in: photoRect)
context.restoreGState()

let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)!
let original = CGImageSourceCreateImageAtIndex(source, 0, nil)!
precondition(original.width == width && original.height == height)
// One contiguous source crop; no internal UI rearrangement or regenerated text.
let cropRect = CGRect(x: 48, y: 312, width: 1194, height: 2294)
let crop = original.cropping(to: cropRect)!
let panelWidth: CGFloat = 1100
let panel = rect(95, 568, panelWidth, cropRect.height * panelWidth / cropRect.width)
let outline = CGPath(roundedRect: panel, cornerWidth: 48, cornerHeight: 48, transform: nil)
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -14), blur: 35,
                  color: color(0x1A1917).withAlphaComponent(0.09).cgColor)
context.addPath(outline)
context.setFillColor(color(0xFBFAF6).cgColor)
context.fillPath()
context.restoreGState()
context.saveGState()
context.addPath(outline)
context.clip()
context.interpolationQuality = .high
context.draw(crop, in: panel)
context.restoreGState()
context.addPath(outline)
context.setStrokeColor(color(0xE3DFD3).cgColor)
context.setLineWidth(1.5)
context.strokePath()
let result = context.makeImage()!
let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, result, nil)
precondition(CGImageDestinationFinalize(destination))
print("Exported \(width) × \(height), opaque sRGB PNG")
print("Headline font: \(font.fontName), \(font.pointSize) px, semibold")
print(outputURL.path)
