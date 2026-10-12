import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = URL(fileURLWithPath: "/Users/ahmadalitariq/Downloads/Screenshot 2026-10-11 at 2.43.45\u{202F}PM.png")
let outputURL = root.appendingPathComponent("app-store/screenshots/en-US/05-your-everyday-diary.png")
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
func text(_ value: String, _ top: CGFloat, _ size: CGFloat,
          _ ink: UInt32, weight: NSFont.Weight = .regular) {
    let label = NSAttributedString(string: value, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color(ink), .kern: size > 90 ? -2.5 : 0
    ])
    precondition(label.size().width <= 1146, "Text overflow")
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    label.draw(at: CGPoint(x: 72, y: CGFloat(height) - top - label.size().height))
    NSGraphicsContext.restoreGraphicsState()
}
func drawCrop(_ source: CGImage, _ crop: CGRect, _ target: CGRect,
              radius: CGFloat, shadow: CGFloat) {
    let path = CGPath(roundedRect: target, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -20), blur: 44,
                      color: color(0x41331C).withAlphaComponent(shadow).cgColor)
    context.addPath(path)
    context.setFillColor(color(0xFBFAF6).cgColor)
    context.fillPath()
    context.restoreGState()
    context.saveGState()
    context.addPath(path)
    context.clip()
    context.interpolationQuality = .high
    context.draw(source.cropping(to: crop)!, in: target)
    context.restoreGState()
    context.addPath(path)
    context.setStrokeColor(color(0xE3DFD3).cgColor)
    context.setLineWidth(1.5)
    context.strokePath()
}
let gradient = CGGradient(colorsSpace: space,
    colors: [color(0xFBFAF6).cgColor, color(0xF4F1E8).cgColor] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: .zero, options: [])
text("Different meals.", 133, 112, 0x1A1917, weight: .semibold)
text("Your everyday diary.", 266, 112, 0x8F6420, weight: .semibold)
text("Meals, photos and estimates, all in one place.", 424, 42, 0x56534C)

let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)!
let original = CGImageSourceCreateImageAtIndex(source, 0, nil)!
precondition(original.width == width && original.height == height)
let crop = CGRect(x: 0, y: 176, width: 1290, height: 2620)
let scale: CGFloat = 980 / 1290
drawCrop(original, crop, rect(155, 600, 980, crop.height * scale), radius: 70, shadow: 0.13)

// Magnify the original sandwich entry at its source position; preserve its estimates.
let mealCrop = CGRect(x: 80, y: 1388, width: 1130, height: 244)
let mealWidth: CGFloat = 1146
let mealHeight = mealCrop.height * mealWidth / mealCrop.width
let sourceCenter = 600 + (mealCrop.midY - crop.minY) * scale
drawCrop(original, mealCrop, rect(72, sourceCenter - mealHeight / 2, mealWidth, mealHeight),
         radius: 40, shadow: 0.24)

let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
print("Exported \(width) × \(height), opaque sRGB PNG")
print("Headline font: \(NSFont.systemFont(ofSize: 112, weight: .semibold).fontName)")
print(outputURL.path)
