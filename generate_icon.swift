import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = CGSize(width: 1024, height: 1024)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

guard let context = CGContext(
    data: nil,
    width: Int(size.width),
    height: Int(size.height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo
) else {
    fatalError("Failed to create context")
}

let rect = CGRect(origin: .zero, size: size)
let cornerRadius: CGFloat = 230

// Draw rounded rect clip
let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
context.addPath(path)
context.clip()

// Gradient background
let colors: [CGFloat] = [
    11/255, 17/255, 32/255, 1,
    30/255, 41/255, 59/255, 1
]
let gradient = CGGradient(colorSpace: colorSpace, colorComponents: colors, locations: [0, 1], count: 2)!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])

// Reset clip
context.resetClip()

// Green brand color
context.setStrokeColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.setLineWidth(32)
context.setLineCap(.round)
context.setLineJoin(.round)

// Upward-trending chart line
// Note: CG bitmap context has y=0 at BOTTOM, so increasing y = higher on screen
let points = [
    CGPoint(x: 260, y: 340),
    CGPoint(x: 440, y: 340),
    CGPoint(x: 620, y: 480),
    CGPoint(x: 800, y: 480)
]

context.move(to: points[0])
for i in 1..<points.count {
    context.addLine(to: points[i])
}
context.strokePath()

// Arrow stem going up-right
context.move(to: CGPoint(x: 800, y: 480))
context.addLine(to: CGPoint(x: 940, y: 620))
context.setStrokeColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.setLineWidth(32)
context.setLineCap(.round)
context.strokePath()

// Arrow head pointing up-right
let arrow = CGMutablePath()
arrow.move(to: CGPoint(x: 940, y: 720))    // tip (highest)
arrow.addLine(to: CGPoint(x: 890, y: 620))  // left base
arrow.addLine(to: CGPoint(x: 990, y: 620)) // right base
arrow.closeSubpath()
context.addPath(arrow)
context.setFillColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.fillPath()

// Get image
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/app_icon.png"
let url = URL(fileURLWithPath: outputPath)
guard let cgImage = context.makeImage() else {
    fatalError("Failed to create image")
}
let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, cgImage, nil)
CGImageDestinationFinalize(destination)
print("Icon saved to \(outputPath)")
