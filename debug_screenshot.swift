#!/usr/bin/env swift

import Foundation
import AppKit

print("🧪 Testing Core Graphics screenshot capture...")

// Test basic screenshot capture
let cgImage = CGWindowListCreateImage(
    .null,
    .optionOnScreenOnly,
    kCGNullWindowID,
    .bestResolution
)

if let image = cgImage {
    print("✅ Screenshot captured successfully!")
    print("📐 Dimensions: \(image.width)×\(image.height)")
    
    // Try to save to a simple location
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_screenshot.jpg")
    
    let bitmapRep = NSBitmapImageRep(cgImage: image)
    bitmapRep.size = NSSize(width: image.width, height: image.height)
    
    let compressionProperties: [NSBitmapImageRep.PropertyKey: Any] = [
        .compressionFactor: NSNumber(value: Float(0.7))
    ]
    
    if let imageData = bitmapRep.representation(using: .jpeg, properties: compressionProperties) {
        do {
            try imageData.write(to: tempURL)
            let fileSize = imageData.count
            let fileSizeStr = ByteCountFormatter().string(fromByteCount: Int64(fileSize))
            print("💾 Saved test screenshot: \(tempURL.path)")
            print("📊 File size: \(fileSizeStr)")
            
            // Open in Finder
            NSWorkspace.shared.activateFileViewerSelecting([tempURL])
        } catch {
            print("❌ Failed to save: \(error)")
        }
    } else {
        print("❌ Failed to encode JPEG")
    }
} else {
    print("❌ Failed to capture screenshot")
} 