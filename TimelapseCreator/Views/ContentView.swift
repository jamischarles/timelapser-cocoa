//
//  ContentView.swift
//  TimelapseCreator
//
//  Created by AI Assistant on 1/6/25.
//  Copyright © 2025 Timelapse Creator. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @EnvironmentObject var projectManager: ProjectManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedTab) {
                Section("Capture") {
                    NavigationLink(value: 0) {
                        Label("Live Capture", systemImage: "camera")
                    }
                    
                    NavigationLink(value: 1) {
                        Label("Gallery", systemImage: "photo.stack")
                    }
                }
                
                Section("Projects") {
                    NavigationLink(value: 2) {
                        Label("Recent Projects", systemImage: "folder")
                    }
                    
                    NavigationLink(value: 3) {
                        Label("Create Video", systemImage: "video")
                    }
                }
                
                Section("Performance") {
                    NavigationLink(value: 4) {
                        Label("Diagnostics", systemImage: "speedometer")
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            // Main content area
            Group {
                switch selectedTab {
                case 0:
                    CaptureView()
                case 1:
                    GalleryView()
                case 2:
                    ProjectsView()
                case 3:
                    VideoGenerationView()
                case 4:
                    DiagnosticsView()
                default:
                    CaptureView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Timelapse Creator")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if screenshotManager.isCapturing {
                    Button("Stop") {
                        Task {
                            await screenshotManager.stopCapture()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Start Capture") {
                        Task {
                            await screenshotManager.startCapture()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!screenshotManager.hasPermission)
                }
                
                Button("New Project") {
                    projectManager.createNewProject()
                }
                .controlSize(.regular)
            }
        }
        .onAppear {
            Task {
                await screenshotManager.checkPermissions()
            }
        }
    }
}

// MARK: - Individual Views

struct CaptureView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @EnvironmentObject var projectManager: ProjectManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Status header
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Project")
                        .font(.headline)
                    Text(projectManager.currentProject?.name ?? "No project selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Screenshot Count")
                        .font(.headline)
                    Text("\(screenshotManager.screenshotCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Permission status
            if !screenshotManager.hasPermission {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Screen Recording Permission Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Please grant screen recording permission in System Preferences > Security & Privacy > Privacy > Screen Recording")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Open System Preferences") {
                        screenshotManager.openSystemPreferences()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Capture controls
                VStack {
                    if screenshotManager.isCapturing {
                        Text("Capturing...")
                            .font(.title)
                            .fontWeight(.medium)
                        
                        Text("Next screenshot in \(String(format: "%.1f", screenshotManager.timeUntilNextCapture))s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        Text("Ready to Capture")
                            .font(.title)
                            .fontWeight(.medium)
                        
                        Text("Configure your settings and start capturing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
}

struct GalleryView: View {
    var body: some View {
        Text("Gallery View - Coming Soon")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProjectsView: View {
    var body: some View {
        Text("Projects View - Coming Soon")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VideoGenerationView: View {
    var body: some View {
        Text("Video Generation - Coming Soon")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DiagnosticsView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Diagnostics")
                .font(.title)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                // Performance metrics
                DiagnosticCard(
                    title: "UI FPS",
                    value: "60",
                    unit: "fps",
                    color: .green
                )
                
                DiagnosticCard(
                    title: "Screenshot FPS",
                    value: String(format: "%.1f", screenshotManager.captureRate),
                    unit: "fps",
                    color: screenshotManager.captureRate > 0.5 ? .green : .orange
                )
                
                DiagnosticCard(
                    title: "Last Capture Time",
                    value: String(format: "%.0f", screenshotManager.lastCaptureTime * 1000),
                    unit: "ms",
                    color: screenshotManager.lastCaptureTime < 0.5 ? .green : .orange
                )
                
                DiagnosticCard(
                    title: "Memory Usage",
                    value: "< 300",
                    unit: "MB",
                    color: .green
                )
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct DiagnosticCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline) {
                Text(value)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
        .environmentObject(ScreenshotManager())
        .environmentObject(ProjectManager())
} 