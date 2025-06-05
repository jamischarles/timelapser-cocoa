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
    @AppStorage("captureAreaMode") private var captureAreaMode: Int = 0
    @AppStorage("imageFormat") private var imageFormat: Int = 0
    @AppStorage("imageQuality") private var imageQuality: Double = 0.8
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
                    Text("Capture Area")
                    Picker("Capture Area", selection: $captureAreaMode) {
                        Text("Full Screen").tag(0)
                        Text("Main Display").tag(1)
                        Text("Custom Area").tag(2)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: captureAreaMode) { newValue in
                        screenshotManager.setCaptureAreaMode(newValue)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Image Format")
                    Picker("Image Format", selection: $imageFormat) {
                        Text("PNG (Lossless)").tag(0)
                        Text("JPEG (Compressed)").tag(1)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: imageFormat) { newValue in
                        screenshotManager.setImageFormat(newValue, quality: imageQuality)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Image Quality: \(String(format: "%.0f", imageQuality * 100))%")
                    Slider(value: $imageQuality, in: 0.1...1.0, step: 0.1)
                        .onChange(of: imageQuality) { newValue in
                            screenshotManager.setImageFormat(imageFormat, quality: newValue)
                        }
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
            
            Section(header: Text("Display Selection")) {
                ForEach(screenshotManager.getDisplayInfo(), id: \.id) { display in
                    Button(action: {
                        screenshotManager.setDisplayID(display.id)
                    }) {
                        HStack {
                            Text(display.name)
                            Spacer()
                            Text("\(Int(display.bounds.width))×\(Int(display.bounds.height))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
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
                
                HStack {
                    Text("Last Capture:")
                    Text("\(String(format: "%.0f", screenshotManager.lastCaptureTime * 1000))ms")
                        .foregroundColor(screenshotManager.lastCaptureTime < 0.5 ? .green : .orange)
                    Spacer()
                }
            }
            
            Section(header: Text("Permissions")) {
                Button("Check Screen Recording Permission") {
                    screenshotManager.checkPermissions()
                }
                
                if !screenshotManager.hasPermission {
                    Button("Open System Preferences") {
                        screenshotManager.openSystemPreferences()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 450)
    }
} 