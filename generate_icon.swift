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

// Draw chart line
context.setStrokeColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.setLineWidth(48)
context.setLineCap(.round)
context.setLineJoin(.round)

let points = [
    CGPoint(x: 232, y: 592),
    CGPoint(x: 332, y: 592),
    CGPoint(x: 432, y: 472),
    CGPoint(x: 532, y: 552),
    CGPoint(x: 632, y: 392),
    CGPoint(x: 732, y: 432),
    CGPoint(x: 792, y: 352)
]

context.move(to: points[0])
for i in 1..<points.count {
    context.addLine(to: points[i])
}
context.strokePath()

// Draw arrow head as filled triangle + line
let arrow = CGMutablePath()
arrow.move(to: CGPoint(x: 712, y: 312))
arrow.addLine(to: CGPoint(x: 832, y: 312))
arrow.addLine(to: CGPoint(x: 832, y: 432))
context.addPath(arrow)
context.setFillColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.fillPath()

// Arrow stem
context.move(to: CGPoint(x: 712, y: 312))
context.addLine(to: CGPoint(x: 832, y: 432))
context.setStrokeColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.setLineWidth(48)
context.strokePath()

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
