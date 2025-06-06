#!/usr/bin/env swift

import Foundation
import AppKit

let fileManager = FileManager.default
let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
let projectsURL = downloadsURL.appendingPathComponent("TimelapseCaptureProjects")

print("🔍 Verifying screenshot storage...")
print("📁 Expected location: \(projectsURL.path)")

if fileManager.fileExists(atPath: projectsURL.path) {
    do {
        let projects = try fileManager.contentsOfDirectory(at: projectsURL, includingPropertiesForKeys: nil, options: [])
        print("📂 Found \(projects.count) project(s)")
        
        for project in projects {
            print("   📁 \(project.lastPathComponent)")
            let screenshots = try fileManager.contentsOfDirectory(at: project, includingPropertiesForKeys: [.fileSizeKey], options: [])
                .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
            print("      Screenshots: \(screenshots.count)")
            
            for screenshot in screenshots.prefix(2) {
                let size = try screenshot.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                print("      📸 \(screenshot.lastPathComponent) (\(ByteCountFormatter().string(fromByteCount: Int64(size))))")
            }
        }
    } catch {
        print("❌ Error: \(error)")
    }
} else {
    print("⚠️  Directory doesn't exist - no screenshots captured yet")
}

print("\n🎯 To open in Finder: open \"\(projectsURL.path)\"") 