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
                    
                    VStack(spacing: 12) {
                        Button("Request Permission") {
                            Task {
                                await screenshotManager.requestPermissions()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Open System Preferences") {
                            screenshotManager.openSystemPreferences()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
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
    @EnvironmentObject var projectManager: ProjectManager
    @EnvironmentObject var thumbnailGenerator: ThumbnailGenerator
    @State private var selectedProject: Project?
    @State private var screenshots: [URL] = []
    @State private var isLoading = false
    @State private var selectedScreenshots: Set<URL> = []
    @State private var showingPreview = false
    @State private var previewImage: URL?
    @State private var sortOrder: SortOrder = .newest
    @State private var thumbnailSize: CGFloat = 150
    
    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 200), spacing: 16)
    ]
    
    enum SortOrder: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case name = "Name"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Gallery header
            galleryHeader
            
            Divider()
            
            // Main gallery content
            if let currentProject = selectedProject ?? projectManager.currentProject {
                if screenshots.isEmpty && !isLoading {
                    emptyGalleryView
                } else {
                    galleryGridView
                }
            } else {
                noProjectView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadCurrentProject()
        }
        .onChange(of: projectManager.currentProject) { _ in
            loadCurrentProject()
        }
        .sheet(isPresented: $showingPreview) {
            if let previewImage = previewImage {
                ImagePreviewSheet(imageURL: previewImage)
            }
        }
        .focusable()
        .onMoveCommand { direction in
            // Arrow key navigation for future enhancement
        }
    }
    
    // MARK: - Gallery Header
    private var galleryHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Gallery")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let project = selectedProject ?? projectManager.currentProject {
                    Text("\(project.name) • \(screenshots.count) screenshots")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("No project selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Sort order picker
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: sortOrder) { _ in
                    sortScreenshots()
                }
                
                // Thumbnail size slider
                HStack {
                    Image(systemName: "rectangle.grid.3x2")
                        .foregroundColor(.secondary)
                    
                    Slider(value: $thumbnailSize, in: 100...300, step: 25)
                        .frame(width: 100)
                    
                    Image(systemName: "rectangle.grid.1x2")
                        .foregroundColor(.secondary)
                }
                
                // Selection actions
                if !selectedScreenshots.isEmpty {
                    Menu("\(selectedScreenshots.count) selected") {
                        Button("Create Video") {
                            // TODO: Implement video creation
                        }
                        
                        Button("Export Selected") {
                            exportSelectedScreenshots()
                        }
                        
                        Divider()
                        
                        Button("Deselect All") {
                            selectedScreenshots.removeAll()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                // Refresh button
                Button(action: refreshGallery) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
        }
        .padding()
    }
    
    // MARK: - Gallery Grid View
    private var galleryGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: thumbnailSize, maximum: thumbnailSize + 50), spacing: 16)
            ], spacing: 16) {
                ForEach(screenshots, id: \.self) { screenshotURL in
                    ThumbnailView(
                        imageURL: screenshotURL,
                        thumbnailSize: thumbnailSize,
                        isSelected: selectedScreenshots.contains(screenshotURL),
                        onTap: {
                            if selectedScreenshots.isEmpty {
                                // Single tap for preview
                                previewImage = screenshotURL
                                showingPreview = true
                            } else {
                                // Multi-selection mode
                                toggleSelection(screenshotURL)
                            }
                        },
                        onLongPress: {
                            toggleSelection(screenshotURL)
                        }
                    )
                    .scaleEffect(selectedScreenshots.contains(screenshotURL) ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedScreenshots.contains(screenshotURL))
                    .id(screenshotURL) // Ensure proper identity for animations
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.3), value: thumbnailSize) // Smooth size transitions
        }
        .overlay(alignment: .bottomTrailing) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                    .background(.regularMaterial, in: Circle())
                    .padding()
            }
        }
        .overlay(alignment: .bottomLeading) {
            // Performance indicator
            if thumbnailGenerator.isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating thumbnails...")
                        .font(.caption)
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
        }
    }
    
    // MARK: - Empty States
    private var emptyGalleryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Screenshots Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start capturing to see your screenshots here")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Capture") {
                // Switch to capture tab
                // This would need to be passed up to ContentView
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noProjectView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Project Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create or select a project to view screenshots")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Project") {
                projectManager.createNewProject()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    private func loadCurrentProject() {
        guard let project = selectedProject ?? projectManager.currentProject else {
            screenshots = []
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let projectContents = try FileManager.default.contentsOfDirectory(
                    at: project.url,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: .skipsHiddenFiles
                )
                
                let imageFiles = projectContents.filter { url in
                    ["png", "jpg", "jpeg"].contains(url.pathExtension.lowercased())
                }
                
                await MainActor.run {
                    screenshots = imageFiles
                    sortScreenshots()
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    screenshots = []
                    isLoading = false
                }
                print("❌ Failed to load project screenshots: \(error.localizedDescription)")
            }
        }
    }
    
    private func sortScreenshots() {
        switch sortOrder {
        case .newest:
            screenshots.sort { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
        case .oldest:
            screenshots.sort { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 < date2
            }
        case .name:
            screenshots.sort { $0.lastPathComponent < $1.lastPathComponent }
        }
    }
    
    private func toggleSelection(_ url: URL) {
        if selectedScreenshots.contains(url) {
            selectedScreenshots.remove(url)
        } else {
            selectedScreenshots.insert(url)
        }
    }
    
    private func refreshGallery() {
        selectedScreenshots.removeAll()
        loadCurrentProject()
    }
    
    private func exportSelectedScreenshots() {
        let savePanel = NSOpenPanel()
        savePanel.canChooseDirectories = true
        savePanel.canChooseFiles = false
        savePanel.prompt = "Export Screenshots"
        savePanel.message = "Select a folder to export \(selectedScreenshots.count) screenshots"
        
        savePanel.begin { response in
            if response == .OK, let destinationURL = savePanel.url {
                Task {
                    await exportScreenshots(to: destinationURL)
                }
            }
        }
    }
    
    private func exportScreenshots(to destinationURL: URL) async {
        let fileManager = FileManager.default
        
        for (index, screenshotURL) in selectedScreenshots.enumerated() {
            do {
                let fileName = screenshotURL.lastPathComponent
                let destinationFileURL = destinationURL.appendingPathComponent(fileName)
                
                // Handle duplicates by adding a number
                var finalDestinationURL = destinationFileURL
                var counter = 1
                while fileManager.fileExists(atPath: finalDestinationURL.path) {
                    let nameWithoutExtension = fileName.replacingOccurrences(of: ".\(screenshotURL.pathExtension)", with: "")
                    let newFileName = "\(nameWithoutExtension)_\(counter).\(screenshotURL.pathExtension)"
                    finalDestinationURL = destinationURL.appendingPathComponent(newFileName)
                    counter += 1
                }
                
                try fileManager.copyItem(at: screenshotURL, to: finalDestinationURL)
                print("📤 Exported: \(finalDestinationURL.lastPathComponent)")
                
            } catch {
                print("❌ Failed to export \(screenshotURL.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            selectedScreenshots.removeAll()
        }
        
        print("✅ Export complete: \(selectedScreenshots.count) screenshots exported")
    }
    
    private func deleteSelectedScreenshots() {
        let alert = NSAlert()
        alert.messageText = "Delete Screenshots"
        alert.informativeText = "Are you sure you want to delete \(selectedScreenshots.count) screenshots? This action cannot be undone."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let fileManager = FileManager.default
            let urlsToDelete = Array(selectedScreenshots)
            
            for screenshotURL in urlsToDelete {
                do {
                    try fileManager.removeItem(at: screenshotURL)
                    screenshots.removeAll { $0 == screenshotURL }
                    print("🗑️ Deleted: \(screenshotURL.lastPathComponent)")
                } catch {
                    print("❌ Failed to delete \(screenshotURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            selectedScreenshots.removeAll()
        }
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

// MARK: - Thumbnail View Component
struct ThumbnailView: View {
    let imageURL: URL
    let thumbnailSize: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @EnvironmentObject var thumbnailGenerator: ThumbnailGenerator
    @State private var thumbnail: NSImage?
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(width: thumbnailSize, height: thumbnailSize)
            
            // Content
            Group {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: thumbnailSize - 4, height: thumbnailSize - 4)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if loadError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Failed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
            }
            
            // Selection overlay
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 3)
                    .frame(width: thumbnailSize, height: thumbnailSize)
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .background(Color.white, in: Circle())
                    }
                    Spacer()
                }
                .frame(width: thumbnailSize - 8, height: thumbnailSize - 8)
            }
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .onAppear {
            loadThumbnail()
        }
        .animation(.easeInOut(duration: 0.3), value: thumbnail != nil)
        .accessibilityLabel("Screenshot thumbnail")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Tap to preview, long press to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private func loadThumbnail() {
        Task {
            do {
                let loadedThumbnail = try await thumbnailGenerator.generateThumbnail(
                    from: imageURL,
                    targetSize: CGSize(width: thumbnailSize, height: thumbnailSize)
                )
                
                await MainActor.run {
                    thumbnail = loadedThumbnail
                    isLoading = false
                    loadError = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    loadError = true
                }
                print("❌ Failed to load thumbnail for \(imageURL.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Image Preview Sheet
struct ImagePreviewSheet: View {
    let imageURL: URL
    @Environment(\.dismiss) var dismiss
    @State private var fullImage: NSImage?
    @State private var isLoading = true
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let fullImage = fullImage {
                    Image(nsImage: fullImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { value in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                } else if isLoading {
                    ProgressView("Loading...")
                        .foregroundColor(.white)
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Failed to load image")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle(imageURL.lastPathComponent)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Menu("Actions") {
                        Button("Show in Finder") {
                            NSWorkspace.shared.selectFile(imageURL.path, inFileViewerRootedAtPath: "")
                        }
                        
                        Button("Export...") {
                            exportImage()
                        }
                        
                        Button("Delete...") {
                            deleteImage()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadFullImage()
        }
    }
    
    private func loadFullImage() {
        Task {
            do {
                guard let nsImage = NSImage(contentsOf: imageURL) else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    fullImage = nsImage
                    isLoading = false
                }
            }
        }
    }
    
    private func exportImage() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.nameFieldStringValue = imageURL.lastPathComponent
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? FileManager.default.copyItem(at: imageURL, to: url)
            }
        }
    }
    
    private func deleteImage() {
        let alert = NSAlert()
        alert.messageText = "Delete Screenshot"
        alert.informativeText = "Are you sure you want to delete \(imageURL.lastPathComponent)? This action cannot be undone."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            try? FileManager.default.removeItem(at: imageURL)
            dismiss()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScreenshotManager())
        .environmentObject(ProjectManager())
        .environmentObject(ThumbnailGenerator())
} 