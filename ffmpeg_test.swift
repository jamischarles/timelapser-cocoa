#!/usr/bin/env swift

import Foundation
import AppKit

func testFFmpegCapture() {
    print("🎬 Testing ffmpeg screen capture...")
    
    // Create temporary file for ffmpeg output
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ffmpeg-test-\(UUID().uuidString).png")
    
    // Set up ffmpeg process
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ffmpeg")
    process.arguments = [
        "-f", "avfoundation",          // Use AVFoundation input
        "-i", "1",                     // Device 1 (Capture screen 0)
        "-frames:v", "1",              // Capture only 1 frame
        "-y",                          // Overwrite output file
        tempURL.path                   // Output file path
    ]
    
    // Capture output for debugging
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    
    do {
        let startTime = CFAbsoluteTimeGetCurrent()
        try process.run()
        process.waitUntilExit()
        
        let captureTime = CFAbsoluteTimeGetCurrent() - startTime
        print("🎬 ffmpeg execution completed in \(String(format: "%.0f", captureTime * 1000))ms")
        
        // Check if process succeeded
        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("❌ ffmpeg failed with status \(process.terminationStatus):")
            print("Error output: \(errorOutput)")
            try? FileManager.default.removeItem(at: tempURL)
            return
        }
        
        // Try to load the captured image
        guard FileManager.default.fileExists(atPath: tempURL.path) else {
            print("❌ ffmpeg output file does not exist: \(tempURL.path)")
            return
        }
        
        let data = try Data(contentsOf: tempURL)
        print("📁 ffmpeg captured \(data.count) bytes")
        
        guard let nsImage = NSImage(data: data) else {
            print("❌ Failed to create NSImage from ffmpeg data")
            try? FileManager.default.removeItem(at: tempURL)
            return
        }
        
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("❌ Failed to create CGImage from NSImage")
            try? FileManager.default.removeItem(at: tempURL)
            return
        }
        
        // Clean up temporary file
        try? FileManager.default.removeItem(at: tempURL)
        
        print("✅ ffmpeg capture successful: \(cgImage.width)×\(cgImage.height)")
        print("🎯 This confirms ffmpeg can capture full screen content!")
        
    } catch {
        print("❌ ffmpeg execution failed: \(error.localizedDescription)")
        try? FileManager.default.removeItem(at: tempURL)
    }
}

// Run the test
testFFmpegCapture() 