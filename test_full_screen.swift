#!/usr/bin/env swift

import Foundation
import CoreGraphics
import AppKit

// Function to get combined display bounds
func getCombinedDisplayBounds() -> CGRect {
    var displayCount: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &displayCount)
    
    var availableDisplays: [CGDirectDisplayID] = Array(repeating: 0, count: Int(displayCount))
    CGGetActiveDisplayList(displayCount, &availableDisplays, &displayCount)
    
    var combinedBounds = CGRect.null
    
    for displayID in availableDisplays {
        let displayBounds = CGDisplayBounds(displayID)
        if combinedBounds.isNull {
            combinedBounds = displayBounds
        } else {
            combinedBounds = combinedBounds.union(displayBounds)
        }
    }
    
    // If no displays detected, fallback to main display bounds
    if combinedBounds.isNull {
        combinedBounds = CGDisplayBounds(CGMainDisplayID())
    }
    
    print("📏 Combined display bounds: \(combinedBounds)")
    return combinedBounds
}

// Test improved full screen capture
func testFullScreenCapture() {
    print("🔍 Testing improved full-screen capture methods...")
    
    // Method 1: CGRect.infinite approach
    print("\n1️⃣ Testing CGRect.infinite approach...")
    let infiniteImage = CGWindowListCreateImage(
        CGRect.infinite,
        .optionOnScreenOnly,
        kCGNullWindowID,
        .bestResolution
    )
    
    if let img = infiniteImage {
        print("✅ CGRect.infinite capture successful: \(img.width)×\(img.height) pixels")
    } else {
        print("❌ CGRect.infinite capture failed")
    }
    
    // Method 2: Combined display bounds approach
    print("\n2️⃣ Testing combined display bounds approach...")
    let combinedBounds = getCombinedDisplayBounds()
    let boundsImage = CGWindowListCreateImage(
        combinedBounds,
        .optionOnScreenOnly,
        kCGNullWindowID,
        .bestResolution
    )
    
    if let img = boundsImage {
        print("✅ Combined bounds capture successful: \(img.width)×\(img.height) pixels")
    } else {
        print("❌ Combined bounds capture failed")
    }
    
    // Method 3: Main display fallback
    print("\n3️⃣ Testing main display fallback...")
    let mainImage = CGDisplayCreateImage(CGMainDisplayID())
    
    if let img = mainImage {
        print("✅ Main display capture successful: \(img.width)×\(img.height) pixels")
    } else {
        print("❌ Main display capture failed")
    }
    
    // Compare dimensions
    print("\n📊 Dimension comparison:")
    if let inf = infiniteImage {
        print("   CGRect.infinite: \(inf.width)×\(inf.height)")
    }
    if let bounds = boundsImage {
        print("   Combined bounds: \(bounds.width)×\(bounds.height)")
    }
    if let main = mainImage {
        print("   Main display: \(main.width)×\(main.height)")
    }
    
    // Test if we can save a sample
    if let bestImage = infiniteImage ?? boundsImage ?? mainImage {
        print("\n💾 Testing file save...")
        let bitmapRep = NSBitmapImageRep(cgImage: bestImage)
        bitmapRep.size = NSSize(width: bestImage.width, height: bestImage.height)
        
        if let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
            let testURL = URL(fileURLWithPath: "/tmp/test_fullscreen.jpg")
            do {
                try jpegData.write(to: testURL)
                let fileSize = jpegData.count
                print("✅ Test image saved: \(testURL.path) (\(ByteCountFormatter().string(fromByteCount: Int64(fileSize))))")
            } catch {
                print("❌ Failed to save test image: \(error)")
            }
        }
    }
}

// Run the test
testFullScreenCapture() 