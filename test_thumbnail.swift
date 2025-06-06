#!/usr/bin/env swift

import Foundation
import AppKit
import CoreImage

func testThumbnailGeneration() {
    print("🖼️ Testing thumbnail generation...")
    
    // Create a simple test image to verify thumbnail generation
    let testImage = NSImage(size: NSSize(width: 1920, height: 1080))
    testImage.lockFocus()
    
    // Draw a simple test pattern
    NSColor.blue.setFill()
    NSRect(x: 0, y: 0, width: 1920, height: 1080).fill()
    
    NSColor.white.setFill()
    NSRect(x: 100, y: 100, width: 200, height: 200).fill()
    
    testImage.unlockFocus()
    
    // Save test image
    let tempDir = FileManager.default.temporaryDirectory
    let testImageURL = tempDir.appendingPathComponent("test_image.png")
    
    guard let tiffData = testImage.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("❌ Failed to create test image")
        return
    }
    
    do {
        try pngData.write(to: testImageURL)
        print("✅ Created test image: \(testImageURL.path)")
        
        // Test thumbnail generation
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let imageSource = CGImageSourceCreateWithURL(testImageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("❌ Failed to load test image for thumbnail")
            return
        }
        
        // Create thumbnail using Core Image
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        let targetSize = CGSize(width: 200, height: 200)
        let imageSize = ciImage.extent.size
        let scale = min(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        
        guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
            print("❌ Failed to create scale filter")
            return
        }
        
        scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        guard let scaledImage = scaleFilter.outputImage else {
            print("❌ Failed to scale image")
            return
        }
        
        let scaledSize = scaledImage.extent.size
        let cropRect = CGRect(x: 0, y: 0, width: min(scaledSize.width, targetSize.width), height: min(scaledSize.height, targetSize.height))
        
        guard let thumbnailCGImage = context.createCGImage(scaledImage, from: cropRect) else {
            print("❌ Failed to render thumbnail")
            return
        }
        
        let thumbnailImage = NSImage(cgImage: thumbnailCGImage, size: targetSize)
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        print("✅ Generated thumbnail in \(String(format: "%.0f", generationTime * 1000))ms")
        print("   Original size: \(Int(imageSize.width))×\(Int(imageSize.height))")
        print("   Thumbnail size: \(Int(thumbnailImage.size.width))×\(Int(thumbnailImage.size.height))")
        
        // Clean up
        try? FileManager.default.removeItem(at: testImageURL)
        
    } catch {
        print("❌ Error: \(error)")
    }
}

// Run test
testThumbnailGeneration()
print("🎯 Thumbnail generation test complete") 