#!/usr/bin/env swift

import Foundation

let fileManager = FileManager.default
let projectsPath = "\(NSHomeDirectory())/Downloads/TimelapseCaptureProjects"

print("🔍 Monitoring \(projectsPath) for new screenshots...")
print("📁 Current time: \(Date())")

// Check if directory exists
if fileManager.fileExists(atPath: projectsPath) {
    do {
        let projects = try fileManager.contentsOfDirectory(atPath: projectsPath)
        print("📂 Found \(projects.count) project(s):")
        
        for project in projects {
            let projectPath = "\(projectsPath)/\(project)"
            let screenshots = try fileManager.contentsOfDirectory(atPath: projectPath)
                .filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".png") }
                .sorted()
            
            print("   📁 \(project): \(screenshots.count) screenshots")
            
            if !screenshots.isEmpty {
                for screenshot in screenshots.suffix(3) {  // Show last 3
                    let fullPath = "\(projectPath)/\(screenshot)"
                    if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
                       let size = attributes[.size] as? Int64,
                       let modDate = attributes[.modificationDate] as? Date {
                        let sizeStr = ByteCountFormatter().string(fromByteCount: size)
                        let timeStr = DateFormatter.localizedString(from: modDate, dateStyle: .none, timeStyle: .medium)
                        print("      📸 \(screenshot) (\(sizeStr)) at \(timeStr)")
                    }
                }
            }
        }
    } catch {
        print("❌ Error reading projects: \(error)")
    }
} else {
    print("⚠️ Projects directory doesn't exist yet")
    print("🚀 It will be created when you start capturing")
} 