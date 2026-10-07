import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceURL = URL(fileURLWithPath: "/Users/ahmadalitariq/Downloads/circa_actual screens/Screenshot 2026-10-07 at 6.37.44\u{202F}PM.png")
let outputURL = root.appendingPathComponent("app-store/screenshots/en-US/01-understand-your-food.png")
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
let font = NSFont.systemFont(ofSize: 112, weight: .semibold)
for (line, top, ink) in [("Understand the food", CGFloat(133), UInt32(0x1A1917)),
                         ("you actually eat.", CGFloat(266), UInt32(0x8F6420))] {
    let text = NSAttributedString(string: line, attributes: [.font: font, .foregroundColor: color(ink), .kern: -2.5])
    precondition(text.size().width <= 1146, "Headline overflow")
    text.draw(at: CGPoint(x: 72, y: CGFloat(height) - top - text.size().height))
}
NSGraphicsContext.restoreGraphicsState()
let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)!
let original = CGImageSourceCreateImageAtIndex(source, 0, nil)!
precondition(original.width == width && original.height == height)
// One contiguous source crop; no internal UI rearrangement or regenerated text.
let cropRect = CGRect(x: 32, y: 340, width: 1226, height: 2240)
let crop = original.cropping(to: cropRect)!
let panelWidth: CGFloat = 1152
let panel = rect(69, 530, panelWidth, cropRect.height * panelWidth / cropRect.width)
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
