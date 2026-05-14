#!/usr/bin/env swift
import AppKit

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage: generate-menubar-icon.swift <input.png> <output-prefix>")
    exit(1)
}

let inputPath = args[1]
let outputPrefix = args[2]

guard let inputImage = NSImage(contentsOfFile: inputPath),
      let cgInput = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    print("Error: Cannot load \(inputPath)")
    exit(1)
}

/// Resize the original image (black lines on white background) to the target size with padding.
func resizeIcon(source: CGImage, size: Int) -> NSImage {
    let outputSize = NSSize(width: size, height: size)
    let padding = CGFloat(size) * 0.05
    let drawRect = NSRect(x: padding, y: padding, width: CGFloat(size) - padding * 2, height: CGFloat(size) - padding * 2)

    let outputImage = NSImage(size: outputSize)
    outputImage.lockFocus()

    // White background
    NSColor.white.setFill()
    NSRect(origin: .zero, size: outputSize).fill()

    // Draw the original black-on-white icon
    NSGraphicsContext.current?.imageInterpolation = .high
    let sourceNS = NSImage(cgImage: source, size: NSSize(width: source.width, height: source.height))
    sourceNS.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    outputImage.unlockFocus()
    return outputImage
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else { fatalError("Cannot create PNG") }
    try! png.write(to: URL(fileURLWithPath: path))
}

// Generate 18x18 (1x) and 36x36 (2x)
let icon1x = resizeIcon(source: cgInput, size: 18)
let icon2x = resizeIcon(source: cgInput, size: 36)

savePNG(icon1x, to: "\(outputPrefix).png")
savePNG(icon2x, to: "\(outputPrefix)@2x.png")

print("Menu bar icons generated: \(outputPrefix).png and \(outputPrefix)@2x.png")
