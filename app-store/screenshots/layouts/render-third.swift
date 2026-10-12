import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = URL(fileURLWithPath: "/Users/ahmadalitariq/Downloads/circa_actual screens/IMG_8389.PNG")
let outputURL = root.appendingPathComponent("app-store/screenshots/en-US/03-your-plate-your-say.png")
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
func text(_ value: String, _ x: CGFloat, _ top: CGFloat, _ size: CGFloat,
          _ ink: UInt32, weight: NSFont.Weight = .regular, mono: Bool = false) {
    let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        : NSFont.systemFont(ofSize: size, weight: weight)
    let label = NSAttributedString(string: value, attributes: [
        .font: font, .foregroundColor: color(ink), .kern: size > 90 ? -2.5 : 0
    ])
    precondition(label.size().width + x <= 1220, "Text overflow")
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    label.draw(at: CGPoint(x: x, y: CGFloat(height) - top - label.size().height))
    NSGraphicsContext.restoreGraphicsState()
}
func card(_ bounds: CGRect, _ radius: CGFloat, _ fill: UInt32, shadow: CGFloat) -> CGPath {
    let path = CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 42,
                      color: color(0x41331C).withAlphaComponent(shadow).cgColor)
    context.addPath(path)
    context.setFillColor(color(fill).cgColor)
    context.fillPath()
    context.restoreGState()
    return path
}
let gradient = CGGradient(colorsSpace: space,
    colors: [color(0xFBFAF6).cgColor, color(0xF4F1E8).cgColor] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: .zero, options: [])
text("Your plate.", 72, 133, 112, 0x1A1917, weight: .semibold)
text("Your say.", 72, 266, 112, 0x8F6420, weight: .semibold)
text("Adjust the amounts. See your estimate update.", 72, 424, 42, 0x56534C)

let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)!
let original = CGImageSourceCreateImageAtIndex(source, 0, nil)!
precondition(original.width == width && original.height == height)
let cropRect = CGRect(x: 0, y: 176, width: 1290, height: 2620)
let panelScale: CGFloat = 980 / 1290
let panel = rect(155, 625, 980, cropRect.height * panelScale)
let outline = card(panel, 70, 0xFBFAF6, shadow: 0.13)
context.saveGState()
context.addPath(outline)
context.clip()
context.interpolationQuality = .high
context.draw(original.cropping(to: cropRect)!, in: panel)
context.restoreGState()
context.addPath(outline)
context.setStrokeColor(color(0xE3DFD3).cgColor)
context.setLineWidth(2)
context.strokePath()

// Editorial outlines highlight original pixels; they do not replace app controls.
for (sourceTop, sourceHeight) in [(CGFloat(682), CGFloat(166)), (1272, 166)] {
    let highlight = rect(155 + 128 * panelScale, 625 + (sourceTop - 176) * panelScale,
                         1030 * panelScale, sourceHeight * panelScale)
    let path = CGPath(roundedRect: highlight, cornerWidth: 22, cornerHeight: 22, transform: nil)
    context.addPath(path)
    context.setStrokeColor(color(0xA77B34).cgColor)
    context.setLineWidth(3)
    context.strokePath()
    context.setFillColor(color(0x8F6420).cgColor)
    context.fillEllipse(in: CGRect(x: highlight.minX - 27, y: highlight.midY - 5, width: 10, height: 10))
}

// A separate magnified crop preserves the captured calculation and Save button.
let floating = rect(56, 2356, 1178, 306)
let floatingPath = card(floating, 46, 0xF4F1E8, shadow: 0.2)
context.addPath(floatingPath)
context.setStrokeColor(color(0xCBB991).cgColor)
context.setLineWidth(2)
context.strokePath()
text("UPDATED ESTIMATE · ENLARGED DETAIL", 95, 2380, 23, 0x8F6420, mono: true)
let summaryCrop = CGRect(x: 40, y: 2495, width: 1210, height: 180)
context.draw(original.cropping(to: summaryCrop)!,
             in: rect(85, 2440, 1120, 180 * 1120 / 1210))

let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
print("Exported \(width) × \(height), opaque sRGB PNG")
print("Headline font: \(NSFont.systemFont(ofSize: 112, weight: .semibold).fontName)")
print(outputURL.path)
