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

// Dark rounded background
let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
context.addPath(bgPath)
context.clip()

let bgColors: [CGFloat] = [
    11/255, 17/255, 32/255, 1,
    30/255, 41/255, 59/255, 1
]
let bgGradient = CGGradient(colorSpace: colorSpace, colorComponents: bgColors, locations: [0, 1], count: 2)!
context.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
context.resetClip()

// --- Bar chart columns (ascending, semi-transparent) ---
// y=0 is BOTTOM in CG bitmap context, so larger y = higher on screen
let barWidth: CGFloat = 70
let barGap: CGFloat = 44
let startX: CGFloat = 170
let baseY: CGFloat = 260          // bottom of bars (low on screen)
let barHeights: [CGFloat] = [160, 240, 320, 400, 480]  // ascending heights
let barColors: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (6/255, 182/255, 212/255, 0.22),
    (16/255, 185/255, 129/255, 0.28),
    (34/255, 197/255, 94/255, 0.34),
    (16/255, 185/255, 129/255, 0.40),
    (34/255, 197/255, 94/255, 0.46),
]

for (i, h) in barHeights.enumerated() {
    let x = startX + CGFloat(i) * (barWidth + barGap)
    let barRect = CGRect(x: x, y: baseY, width: barWidth, height: h)
    let barPath = CGPath(roundedRect: barRect, cornerWidth: 8, cornerHeight: 8, transform: nil)
    context.addPath(barPath)
    let (r, g, b, a) = barColors[i]
    context.setFillColor(red: r, green: g, blue: b, alpha: a)
    context.fillPath()
}

// --- Upward trend line (thick, rounded, bright green) ---
// Starts low-left, ends high-right
context.setStrokeColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.setLineWidth(38)
context.setLineCap(.round)
context.setLineJoin(.round)

let linePoints = [
    CGPoint(x: 205, y: 420),   // low left
    CGPoint(x: 355, y: 500),   // up
    CGPoint(x: 505, y: 440),   // small dip
    CGPoint(x: 655, y: 580),   // up
    CGPoint(x: 805, y: 520)    // higher
]

context.move(to: linePoints[0])
for i in 1..<linePoints.count {
    context.addLine(to: linePoints[i])
}
context.strokePath()

// Arrow stem going up-right from last point
context.move(to: CGPoint(x: 805, y: 520))
context.addLine(to: CGPoint(x: 940, y: 660))
context.setStrokeColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.setLineWidth(38)
context.setLineCap(.round)
context.strokePath()

// Arrow head pointing UP-RIGHT
// Tip must be HIGHER (larger y) than base
let arrow = CGMutablePath()
arrow.move(to: CGPoint(x: 940, y: 760))     // tip (highest)
arrow.addLine(to: CGPoint(x: 875, y: 640))  // left base
arrow.addLine(to: CGPoint(x: 1005, y: 640)) // right base
arrow.closeSubpath()
context.addPath(arrow)
context.setFillColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
context.fillPath()

// Subtle glow behind arrow tip
let glow = CGMutablePath()
glow.addEllipse(in: CGRect(x: 900, y: 730, width: 80, height: 80))
context.addPath(glow)
context.setFillColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 0.12)
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
