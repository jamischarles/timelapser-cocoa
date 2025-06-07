#!/usr/bin/env swift

import Foundation
import CoreGraphics
import AppKit

print("🧪 Testing Full Screen Capture Fix...")
print("📋 This test verifies that CGWindowListCreateImage captures the entire desktop")

// Test the fixed approach (what we implemented)
print("\n✅ Testing FIXED approach: CGWindowListCreateImage with .null")
let fixedImage = CGWindowListCreateImage(
    .null,  // Capture entire desktop across all displays
    .optionOnScreenOnly,
    kCGNullWindowID,
    .bestResolution
)

if let image = fixedImage {
    print("✅ Fixed approach successful!")
    print("📐 Dimensions: \(image.width)×\(image.height) pixels")
    
    // Save test image
    let bitmapRep = NSBitmapImageRep(cgImage: image)
    bitmapRep.size = NSSize(width: image.width, height: image.height)
    
    if let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
        let testURL = URL(fileURLWithPath: "/tmp/fixed_fullscreen_test.jpg")
        do {
            try jpegData.write(to: testURL)
            let fileSize = jpegData.count
            print("💾 Test image saved: \(testURL.path)")
            print("📊 File size: \(ByteCountFormatter().string(fromByteCount: Int64(fileSize)))")
            
            // Open the image to verify it shows full desktop
            print("🔍 Opening image for visual verification...")
            NSWorkspace.shared.activateFileViewerSelecting([testURL])
        } catch {
            print("❌ Failed to save test image: \(error)")
        }
    }
} else {
    print("❌ Fixed approach failed!")
}

// Test the old broken approach for comparison
print("\n❌ Testing OLD approach: CGDisplayCreateImage (main display only)")
let oldImage = CGDisplayCreateImage(CGMainDisplayID())

if let image = oldImage {
    print("✅ Old approach successful (but limited)")
    print("📐 Dimensions: \(image.width)×\(image.height) pixels")
    
    // Save comparison image
    let bitmapRep = NSBitmapImageRep(cgImage: image)
    bitmapRep.size = NSSize(width: image.width, height: image.height)
    
    if let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
        let testURL = URL(fileURLWithPath: "/tmp/old_display_only_test.jpg")
        do {
            try jpegData.write(to: testURL)
            print("💾 Comparison image saved: \(testURL.path)")
        } catch {
            print("❌ Failed to save comparison image: \(error)")
        }
    }
} else {
    print("❌ Old approach failed!")
}

// Compare results
if let fixed = fixedImage, let old = oldImage {
    print("\n📊 COMPARISON:")
    print("   Fixed (CGWindowListCreateImage): \(fixed.width)×\(fixed.height)")
    print("   Old (CGDisplayCreateImage): \(old.width)×\(old.height)")
    
    if fixed.width >= old.width && fixed.height >= old.height {
        print("✅ Fixed approach captures equal or larger area!")
    } else {
        print("⚠️ Fixed approach captures smaller area - this might indicate an issue")
    }
    
    print("\n🎯 EXPECTED BEHAVIOR:")
    print("   - Fixed approach should capture ALL windows, desktop, and content")
    print("   - Old approach only captures the display buffer (may miss some windows)")
    print("   - Both images should be saved to /tmp/ for visual comparison")
}

print("\n🔍 MANUAL VERIFICATION:")
print("   1. Check that /tmp/fixed_fullscreen_test.jpg shows your ENTIRE desktop")
print("   2. Verify it includes all windows, dock, menu bar, and desktop background")
print("   3. Compare with /tmp/old_display_only_test.jpg to see the difference")
print("   4. The fixed version should show all on-screen content correctly") 