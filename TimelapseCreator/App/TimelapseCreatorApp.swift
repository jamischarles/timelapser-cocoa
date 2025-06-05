//
//  TimelapseCreatorApp.swift
//  TimelapseCreator
//
//  Created by AI Assistant on 1/6/25.
//  Copyright © 2025 Timelapse Creator. All rights reserved.
//

import SwiftUI

@main
struct TimelapseCreatorApp: App {
    // Shared app state
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var projectManager = ProjectManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenshotManager)
                .environmentObject(projectManager)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(screenshotManager)
                .environmentObject(projectManager)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @AppStorage("captureInterval") private var captureInterval: Double = 5.0
    @AppStorage("thumbnailQuality") private var thumbnailQuality: Double = 0.8
    @AppStorage("videoQuality") private var videoQuality: Double = 0.9
    
    var body: some View {
        Form {
            Section(header: Text("Capture Settings")) {
                VStack(alignment: .leading) {
                    Text("Capture Interval: \(String(format: "%.1f", captureInterval)) seconds")
                    Slider(value: $captureInterval, in: 1.0...30.0, step: 0.5)
                }
                
                VStack(alignment: .leading) {
                    Text("Thumbnail Quality: \(String(format: "%.0f", thumbnailQuality * 100))%")
                    Slider(value: $thumbnailQuality, in: 0.1...1.0, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Video Quality: \(String(format: "%.0f", videoQuality * 100))%")
                    Slider(value: $videoQuality, in: 0.1...1.0, step: 0.1)
                }
            }
            
            Section(header: Text("Performance")) {
                HStack {
                    Text("Target FPS:")
                    Text("60 fps")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack {
                    Text("Memory Usage:")
                    Text("< 300 MB")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            Section(header: Text("Permissions")) {
                Button("Check Screen Recording Permission") {
                    screenshotManager.checkPermissions()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }
} 