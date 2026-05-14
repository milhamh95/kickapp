#!/usr/bin/env swift
import AppKit
import CoreImage

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage: recolor-icon.swift <input.png> <output.png>")
    exit(1)
}

let inputPath = args[1]
let outputPath = args[2]

// Medium blue background color
let bgColor = NSColor(red: 0.30, green: 0.56, blue: 0.85, alpha: 1.0) // #4D8FD9

guard let inputImage = NSImage(contentsOfFile: inputPath) else {
    print("Error: Cannot load \(inputPath)")
    exit(1)
}

let size = inputImage.size
let outputImage = NSImage(size: size)

outputImage.lockFocus()

// Draw light blue background with rounded corners (macOS icon style)
let rect = NSRect(origin: .zero, size: size)
let cornerRadius = size.width * 0.18 // standard macOS icon corner radius
let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
bgColor.setFill()
path.fill()

// Draw the original icon, inverting black to white
// First draw the original image into a CGImage
guard let cgInput = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Error: Cannot get CGImage")
    exit(1)
}

let ciInput = CIImage(cgImage: cgInput)

// Invert colors: this turns black lines to white
guard let invertFilter = CIFilter(name: "CIColorInvert") else {
    print("Error: Cannot create invert filter")
    exit(1)
}
invertFilter.setValue(ciInput, forKey: kCIInputImageKey)

guard let invertedCI = invertFilter.outputImage else {
    print("Error: Invert filter failed")
    exit(1)
}

// Render the inverted CIImage to a CGImage
let context = CIContext()
guard let invertedCG = context.createCGImage(invertedCI, from: invertedCI.extent) else {
    print("Error: Cannot render inverted image")
    exit(1)
}

let invertedNS = NSImage(cgImage: invertedCG, size: size)

// Add padding so the icon doesn't touch the edges
let padding = size.width * 0.12
let iconRect = NSRect(
    x: padding,
    y: padding,
    width: size.width - padding * 2,
    height: size.height - padding * 2
)

// Clip to the rounded rect so the white corners of the inverted image don't leak
path.addClip()

invertedNS.draw(in: iconRect, from: .zero, operation: .destinationIn, fraction: 1.0)

// The invert turned white background to black — we need a different approach.
// Let's use the original as a mask: where it's black (the lines), draw white.
NSGraphicsContext.current?.restoreGraphicsState()
outputImage.unlockFocus()

// Better approach: use the original image as a mask
let finalImage = NSImage(size: size)
finalImage.lockFocus()

// 1. Draw rounded light blue background
let finalPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
bgColor.setFill()
finalPath.fill()

// 2. Create a white version of the icon by compositing
// The source image has black lines on white background.
// We want white lines on transparent, then draw over the blue background.

// Create a temporary image: white everywhere, masked by the darkness of the original
let maskImage = NSImage(size: size)
maskImage.lockFocus()

// Fill white
NSColor.white.setFill()
iconRect.fill()

// Use the original as a mask — draw it with destinationIn compositing
// This keeps white only where the original has content (dark pixels)
inputImage.draw(in: iconRect, from: .zero, operation: .destinationIn, fraction: 1.0)

maskImage.unlockFocus()

// But the original has white background too, so destinationIn won't isolate lines.
// Instead: draw original, then color-invert just the drawn area.

// Simpler approach: the image is black-on-white.
// Step 1: Make the white parts transparent by using the image as alpha mask
// Step 2: Recolor the remaining (black) parts to white

// Let's use Core Graphics directly for precision
guard let cgOrig = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Error: Cannot get CGImage")
    exit(1)
}

let w = cgOrig.width
let h = cgOrig.height
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bytesPerPixel = 4
let bytesPerRow = bytesPerPixel * w
let bitmapData = UnsafeMutablePointer<UInt8>.allocate(capacity: h * bytesPerRow)
defer { bitmapData.deallocate() }

guard let cgContext = CGContext(
    data: bitmapData,
    width: w,
    height: h,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Error: Cannot create CGContext")
    exit(1)
}

cgContext.draw(cgOrig, in: CGRect(x: 0, y: 0, width: w, height: h))

// Process pixels: black lines -> white with full alpha, white background -> transparent
for y in 0..<h {
    for x in 0..<w {
        let offset = (y * bytesPerRow) + (x * bytesPerPixel)
        let r = bitmapData[offset]
        let g = bitmapData[offset + 1]
        let b = bitmapData[offset + 2]
        let a = bitmapData[offset + 3]

        // Calculate luminance (how bright the pixel is)
        let luminance = (Int(r) + Int(g) + Int(b)) / 3

        if luminance < 180 && a > 0 {
            // Dark pixel (the lines) -> make white, keep proportional alpha
            let darkness = 255 - luminance
            let newAlpha = min(255, darkness * Int(a) / 255)
            bitmapData[offset] = 255     // R
            bitmapData[offset + 1] = 255 // G
            bitmapData[offset + 2] = 255 // B
            bitmapData[offset + 3] = UInt8(newAlpha)
        } else {
            // Light pixel (background) -> transparent
            bitmapData[offset] = 0
            bitmapData[offset + 1] = 0
            bitmapData[offset + 2] = 0
            bitmapData[offset + 3] = 0
        }
    }
}

guard let processedCG = cgContext.makeImage() else {
    print("Error: Cannot make processed image")
    exit(1)
}

let processedNS = NSImage(cgImage: processedCG, size: size)

// Draw the white-lines-on-transparent over the blue background
processedNS.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)

finalImage.unlockFocus()

// Save as PNG
guard let tiffData = finalImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:])
else {
    print("Error: Cannot create PNG data")
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Icon saved to \(outputPath)")
} catch {
    print("Error writing file: \(error)")
    exit(1)
}
