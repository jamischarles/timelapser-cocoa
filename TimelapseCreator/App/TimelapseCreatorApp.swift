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
    @StateObject private var thumbnailGenerator = ThumbnailGenerator()
    
    var body: some Scene {
        WindowGroup {
                    ContentView()
            .environmentObject(screenshotManager)
            .environmentObject(projectManager)
            .environmentObject(thumbnailGenerator)
            .environmentObject(VideoGenerator())
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    // Connect thumbnail generator to screenshot manager
                    screenshotManager.setThumbnailGenerator(thumbnailGenerator)
                    // Connect project manager to screenshot manager
                    screenshotManager.setProjectManager(projectManager)
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(screenshotManager)
                .environmentObject(projectManager)
                .environmentObject(thumbnailGenerator)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @EnvironmentObject var thumbnailGenerator: ThumbnailGenerator
    @AppStorage("captureInterval") private var captureInterval: Double = 5.0
    @AppStorage("captureAreaMode") private var captureAreaMode: Int = 0
    @AppStorage("imageFormat") private var imageFormat: Int = 1 // Default to JPEG for smaller files
    @AppStorage("imageQuality") private var imageQuality: Double = 0.7 // Reduced for smaller file sizes
    @AppStorage("thumbnailSize") private var thumbnailSize: Double = 150 // Reduced for faster generation
    @AppStorage("thumbnailQuality") private var thumbnailQuality: Double = 0.8
    @AppStorage("enableThumbnailCache") private var enableThumbnailCache: Bool = true
    @AppStorage("maxCacheSize") private var maxCacheSize: Int = 100
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
                        Text("Specific Window").tag(2)
                        Text("Custom Region").tag(3)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: captureAreaMode) { newValue in
                        screenshotManager.setCaptureAreaMode(newValue)
                    }
                    
                    // Window selection for specific window mode
                    if captureAreaMode == 2 {
                        VStack(alignment: .leading) {
                            Text("Select Window:")
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(screenshotManager.availableWindows, id: \.id) { window in
                                        Button(action: {
                                            screenshotManager.setSelectedWindow(window.id)
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(window.name)
                                                        .lineLimit(1)
                                                    Text(window.ownerName)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                                if screenshotManager.selectedWindowID == window.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                            .border(Color.gray.opacity(0.3), width: 1)
                            .cornerRadius(4)
                            
                            Button("Refresh Windows") {
                                Task {
                                    await screenshotManager.detectWindows()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // Region selection for custom region mode
                    if captureAreaMode == 3 {
                        VStack(alignment: .leading) {
                            Text("Custom Region:")
                            if screenshotManager.customRegion.isEmpty {
                                Button("Select Region") {
                                    screenshotManager.isSelectingRegion = true
                                    // TODO: Implement region selection overlay
                                }
                                .buttonStyle(.bordered)
                            } else {
                                VStack(alignment: .leading) {
                                    Text("Selected: \(Int(screenshotManager.customRegion.width))×\(Int(screenshotManager.customRegion.height))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Button("Change Region") {
                                            screenshotManager.isSelectingRegion = true
                                        }
                                        Button("Clear") {
                                            screenshotManager.setCustomRegion(.zero)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
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
                    Text("Video Quality: \(String(format: "%.0f", videoQuality * 100))%")
                    Slider(value: $videoQuality, in: 0.1...1.0, step: 0.1)
                }
            }
            
            Section(header: Text("Thumbnail Settings")) {
                VStack(alignment: .leading) {
                    Text("Thumbnail Size: \(Int(thumbnailSize))px")
                    Slider(value: $thumbnailSize, in: 100...400, step: 50)
                        .onChange(of: thumbnailSize) { newValue in
                            thumbnailGenerator.updateThumbnailSize(newValue)
                        }
                }
                
                VStack(alignment: .leading) {
                    Text("Thumbnail Quality: \(String(format: "%.0f", thumbnailQuality * 100))%")
                    Slider(value: $thumbnailQuality, in: 0.1...1.0, step: 0.1)
                }
                
                Toggle("Enable Thumbnail Cache", isOn: $enableThumbnailCache)
                    .onChange(of: enableThumbnailCache) { newValue in
                        thumbnailGenerator.updateCacheSettings(enabled: newValue, maxSize: maxCacheSize)
                    }
                
                if enableThumbnailCache {
                    VStack(alignment: .leading) {
                        Text("Max Cache Size: \(maxCacheSize) items")
                        Slider(value: Binding(
                            get: { Double(maxCacheSize) },
                            set: { maxCacheSize = Int($0) }
                        ), in: 50...500, step: 50)
                        .onChange(of: maxCacheSize) { newValue in
                            thumbnailGenerator.updateCacheSettings(enabled: enableThumbnailCache, maxSize: newValue)
                        }
                    }
                    
                    let cacheStats = thumbnailGenerator.getCacheStats()
                    HStack {
                        Text("Cache Usage:")
                        Text("\(cacheStats.thumbnailCount) thumbnails, \(cacheStats.estimatedMemory)")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Clear Cache") {
                            thumbnailGenerator.clearCache()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
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
                
                Button("Reset & Request Permissions") {
                    Task {
                        await screenshotManager.resetPermissions()
                    }
                }
                .foregroundColor(.orange)
                
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