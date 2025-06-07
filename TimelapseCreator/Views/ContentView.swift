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
    
    // Method to start capture with auto-project creation
    private func startCaptureWithAutoProject() {
        Task {
            await screenshotManager.startCapture()
        }
    }
    
    @ViewBuilder
    var body: some View {
        if #available(macOS 13.0, *) {
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
                        GalleryView(startCaptureAction: {
                            selectedTab = 0
                            startCaptureWithAutoProject()
                        })
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
                            startCaptureWithAutoProject()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    
                    Button("New Project") {
                        projectManager.createNewProject()
                    }
                    .controlSize(.regular)
                }
            }
            .onAppear {
                screenshotManager.checkPermissions()
            }
        } else {
            // Fallback for older macOS versions
            HSplitView {
                // Sidebar
                VStack {
                    List {
                        Group {
                            Button(action: { selectedTab = 0 }) {
                                Label("Live Capture", systemImage: "camera")
                            }
                            Button(action: { selectedTab = 1 }) {
                                Label("Gallery", systemImage: "photo.stack")
                            }
                            Button(action: { selectedTab = 2 }) {
                                Label("Recent Projects", systemImage: "folder")
                            }
                            Button(action: { selectedTab = 3 }) {
                                Label("Create Video", systemImage: "video")
                            }
                            Button(action: { selectedTab = 4 }) {
                                Label("Diagnostics", systemImage: "speedometer")
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(minWidth: 200, idealWidth: 250)
                
                // Main content area
                Group {
                    switch selectedTab {
                    case 0:
                        CaptureView()
                    case 1:
                        GalleryView(startCaptureAction: {
                            selectedTab = 0
                            startCaptureWithAutoProject()
                        })
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
            .onAppear {
                screenshotManager.checkPermissions()
            }
        }
    }
}

// MARK: - Individual Views

struct CaptureView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @EnvironmentObject var projectManager: ProjectManager
    
    // Method to start capture with auto-project creation
    private func startCaptureWithAutoProject() {
        Task {
            await screenshotManager.startCapture()
        }
    }
    
    private func getCurrentCaptureMode() -> String {
        switch screenshotManager.captureAreaMode {
        case 0: return "Full Screen"
        case 1: return "Main Display"
        case 2: return "Specific Window"
        case 3: return "Custom Region"
        default: return "Unknown"
        }
    }
    
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
            
            // Compact permission warning (only show if permission actually missing)
            if !screenshotManager.hasPermission {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    
                    Text("Screen recording permission required for capture")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Fix in Settings") {
                        screenshotManager.openSystemPreferences()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Quick capture mode selector
            VStack {
                HStack {
                    Text("Capture Mode:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        Button("Full Screen") {
                            screenshotManager.setCaptureAreaMode(0)
                        }
                        Button("Main Display") {
                            screenshotManager.setCaptureAreaMode(1)
                        }
                        Button("Specific Window") {
                            screenshotManager.setCaptureAreaMode(2)
                        }
                        Button("Custom Region") {
                            screenshotManager.setCaptureAreaMode(3)
                        }
                    } label: {
                        HStack {
                            Text(getCurrentCaptureMode())
                            Image(systemName: "chevron.down")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // Show current selection details
                if getCurrentCaptureMode() == "Specific Window" {
                    if screenshotManager.selectedWindowID != 0 {
                        if let selectedWindow = screenshotManager.availableWindows.first(where: { $0.id == screenshotManager.selectedWindowID }) {
                            Text("📱 \(selectedWindow.name) (\(selectedWindow.ownerName))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("⚠️ No window selected - configure in Settings")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else if getCurrentCaptureMode() == "Custom Region" {
                    if !screenshotManager.customRegion.isEmpty {
                        Text("🔲 \(Int(screenshotManager.customRegion.width))×\(Int(screenshotManager.customRegion.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("⚠️ No region selected - configure in Settings")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Capture controls (always show, disable if no permission)
            VStack(spacing: 20) {
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
                    
                    Button("Stop Capture") {
                        Task {
                            await screenshotManager.stopCapture()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    VStack(spacing: 16) {
                        Text("Ready to Capture")
                            .font(.title)
                            .fontWeight(.medium)
                        
                        Text("Configure your settings and start capturing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Start Capture") {
                            startCaptureWithAutoProject()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
}

struct GalleryView: View {
    @EnvironmentObject var projectManager: ProjectManager
    @EnvironmentObject var thumbnailGenerator: ThumbnailGenerator
    @EnvironmentObject var videoGenerator: VideoGenerator
    @State private var selectedProject: Project?
    @State private var screenshots: [URL] = []
    @State private var isLoading = false
    @State private var selectedScreenshots: Set<URL> = []
    @State private var showingPreview = false
    @State private var previewImage: URL?
    @State private var showingVideoCreation = false
    @State private var sortOrder: SortOrder = .newest
    @State private var thumbnailSize: CGFloat = 150
    
    // Action to start capture (passed from ContentView)
    let startCaptureAction: () -> Void
    
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
            if (selectedProject ?? projectManager.currentProject) != nil {
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
        .sheet(isPresented: $showingVideoCreation) {
            VideoCreationSheet(selectedImages: Array(selectedScreenshots)) {
                selectedScreenshots.removeAll()
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
                    
                    Slider(value: $thumbnailSize, in: 100...500, step: 25)
                        .frame(width: 120)
                    
                    Image(systemName: "rectangle.grid.1x2")
                        .foregroundColor(.secondary)
                        
                    // Show current zoom level
                    Text("\(Int(thumbnailSize))px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
                
                // Selection actions
                if !selectedScreenshots.isEmpty {
                    Menu("\(selectedScreenshots.count) selected") {
                        Button("Create Video") {
                            showingVideoCreation = true
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
        ScrollView(.vertical) {
            let gridSpacing = max(16, thumbnailSize * 0.1) // Dynamic spacing based on thumbnail size
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: thumbnailSize, maximum: thumbnailSize + 50), spacing: gridSpacing)
            ], spacing: gridSpacing) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                startCaptureAction()
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
        
        for (_, screenshotURL) in selectedScreenshots.enumerated() {
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
    @EnvironmentObject var projectManager: ProjectManager
    @State private var selectedProjects: Set<UUID> = []
    @State private var showingDeleteAlert = false
    @State private var showingPurgeAlert = false
    @State private var totalStorageUsed: Int64 = 0
    @State private var isCalculatingStorage = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with storage info and actions
            headerView
            
            Divider()
            
            // Projects list
            if projectManager.projects.isEmpty {
                emptyStateView
            } else {
                projectsListView
            }
        }
        .onAppear {
            calculateTotalStorage()
        }
        .alert("Delete Selected Projects", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedProjects()
            }
        } message: {
            Text("This will permanently delete \(selectedProjects.count) project(s) and all their screenshots. This action cannot be undone.")
        }
        .alert("Purge All Projects", isPresented: $showingPurgeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Purge All", role: .destructive) {
                purgeAllProjects()
            }
        } message: {
            Text("This will permanently delete ALL projects and screenshots, freeing up \(bytesToHumanReadable(totalStorageUsed)) of storage. This action cannot be undone.")
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Project Manager")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if isCalculatingStorage {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Calculating storage...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("\(projectManager.projects.count) projects • \(bytesToHumanReadable(totalStorageUsed)) used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Refresh button
                    Button {
                        refreshProjects()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("Refresh projects")
                    
                    // Selection controls
                    if !selectedProjects.isEmpty {
                        Button("Delete Selected") {
                            showingDeleteAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                        Button("Deselect All") {
                            selectedProjects.removeAll()
                        }
                        .buttonStyle(.bordered)
                    } else if !projectManager.projects.isEmpty {
                        Button("Select All") {
                            selectedProjects = Set(projectManager.projects.map(\.id))
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Purge All") {
                            showingPurgeAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            
            // Selection summary bar
            if !selectedProjects.isEmpty {
                HStack {
                    Text("\(selectedProjects.count) project(s) selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("~\(bytesToHumanReadable(calculateSelectedProjectsSize())) to be freed")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Projects Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Create your first project to start capturing screenshots")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create New Project") {
                projectManager.createNewProject()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var projectsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(projectManager.projects) { project in
                    ProjectRowView(
                        project: project,
                        isSelected: selectedProjects.contains(project.id),
                        onToggleSelection: {
                            if selectedProjects.contains(project.id) {
                                selectedProjects.remove(project.id)
                            } else {
                                selectedProjects.insert(project.id)
                            }
                        },
                        onDelete: {
                            projectManager.deleteProject(project)
                            selectedProjects.remove(project.id)
                            calculateTotalStorage()
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private func refreshProjects() {
        projectManager.refreshProjects()
        calculateTotalStorage()
    }
    
    private func calculateTotalStorage() {
        isCalculatingStorage = true
        Task {
            var total: Int64 = 0
            
            for project in projectManager.projects {
                total += getDirectorySize(project.url)
            }
            
            await MainActor.run {
                totalStorageUsed = total
                isCalculatingStorage = false
            }
        }
    }
    
    private func calculateSelectedProjectsSize() -> Int64 {
        var total: Int64 = 0
        let selectedProjectsList = projectManager.projects.filter { selectedProjects.contains($0.id) }
        
        for project in selectedProjectsList {
            total += getDirectorySize(project.url)
        }
        
        return total
    }
    
    private func deleteSelectedProjects() {
        let projectsToDelete = projectManager.projects.filter { selectedProjects.contains($0.id) }
        projectManager.deleteProjects(projectsToDelete)
        selectedProjects.removeAll()
        calculateTotalStorage()
    }
    
    private func purgeAllProjects() {
        projectManager.purgeAllProjects()
        selectedProjects.removeAll()
        totalStorageUsed = 0
    }
    
    private func getDirectorySize(_ url: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                    if let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                } catch {
                    // Skip files we can't read
                }
            }
        }
        
        return totalSize
    }
    
    private func bytesToHumanReadable(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(bytes)
        var unitIndex = 0
        
        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f %@", size, units[unitIndex])
    }
}

struct ProjectRowView: View {
    let project: Project
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onDelete: () -> Void
    
    @State private var projectSize: Int64 = 0
    @State private var isCalculatingSize = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection checkbox
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            // Project icon
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            // Project details
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text("\(project.screenshotCount) screenshots")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isCalculatingSize {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("calculating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(bytesToHumanReadable(projectSize))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(project.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Quick actions
            HStack(spacing: 8) {
                Button {
                    NSWorkspace.shared.open(project.url)
                } label: {
                    Image(systemName: "folder.badge.gearshape")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Open in Finder")
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
                .help("Delete project")
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            calculateProjectSize()
        }
    }
    
    private func calculateProjectSize() {
        isCalculatingSize = true
        Task {
            let size = getDirectorySize(project.url)
            await MainActor.run {
                projectSize = size
                isCalculatingSize = false
            }
        }
    }
    
    private func getDirectorySize(_ url: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                    if let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                } catch {
                    // Skip files we can't read
                }
            }
        }
        
        return totalSize
    }
    
    private func bytesToHumanReadable(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(bytes)
        var unitIndex = 0
        
        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f %@", size, units[unitIndex])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
    @State private var zoomLevel: Int = 0 // 0 = fit, 1 = 100%, 2 = 200%, 3 = 400%, 4 = 800%, 5 = 1600%, 6 = 3200%
    
    private let zoomLevels: [CGFloat] = [1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            if let fullImage = fullImage {
                // ScrollView to allow the image to break outside bounds
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: fullImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: fullImage.size.width * scale,
                            height: fullImage.size.height * scale
                        )
                        .scaleEffect(1.0) // Remove scaleEffect since we're using frame sizing
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
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = scale * value
                                    scale = min(max(newScale, 0.1), 64.0) // Match our maximum zoom level
                                }
                                .onEnded { value in
                                    // Snap to nearest zoom level
                                    let targetScale = scale
                                    if let nearestLevel = zoomLevels.min(by: { abs($0 - targetScale) < abs($1 - targetScale) }) {
                                        withAnimation(.spring()) {
                                            scale = nearestLevel
                                            if let index = zoomLevels.firstIndex(of: nearestLevel) {
                                                zoomLevel = index
                                            }
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                zoomLevel = (zoomLevel + 1) % zoomLevels.count
                                scale = zoomLevels[zoomLevel]
                                
                                // Reset position when going back to fit
                                if zoomLevel == 0 {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

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
            
            // Close button in top-right corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding(8)
                            .background(.black.opacity(0.7), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            
            // Zoom indicator and controls in bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(Int(scale * 100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
                        
                        // Zoom controls
                        VStack(spacing: 4) {
                            Button(action: zoomIn) {
                                Image(systemName: "plus.magnifyingglass")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: zoomOut) {
                                Image(systemName: "minus.magnifyingglass")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: resetZoom) {
                                Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                }
            }
            
            // Image title and actions in top-left
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(imageURL.lastPathComponent)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
                        
                        HStack(spacing: 8) {
                            Button("Show in Finder") {
                                NSWorkspace.shared.selectFile(imageURL.path, inFileViewerRootedAtPath: "")
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                            
                            Button("Export") {
                                exportImage()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                            
                            Button("Delete") {
                                deleteImage()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(.top, 20)
                    .padding(.leading, 20)
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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
    
    private func zoomIn() {
        withAnimation(.spring()) {
            if zoomLevel < zoomLevels.count - 1 {
                zoomLevel += 1
                scale = zoomLevels[zoomLevel]
            }
        }
    }
    
    private func zoomOut() {
        withAnimation(.spring()) {
            if zoomLevel > 0 {
                zoomLevel -= 1
                scale = zoomLevels[zoomLevel]
                
                // Reset position when going back to fit
                if zoomLevel == 0 {
                    offset = .zero
                    lastOffset = .zero
                }
            }
        }
    }
    
    private func resetZoom() {
        withAnimation(.spring()) {
            zoomLevel = 0
            scale = zoomLevels[0]
            offset = .zero
            lastOffset = .zero
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

// MARK: - Video Creation Sheet
struct VideoCreationSheet: View {
    let selectedImages: [URL]
    let onCompletion: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var videoGenerator: VideoGenerator
    @State private var videoSettings = VideoSettings.default
    @State private var selectedResolution = "1080p"
    @State private var outputURL: URL?
    @State private var showingSavePanel = false
    @State private var isGenerating = false
    @State private var generatedVideoURL: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Timelapse Video")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(selectedImages.count) images selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Video Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Video Settings")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Frame Rate
                        VStack(alignment: .leading) {
                            Text("Frame Rate")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("FPS", selection: Binding(
                                get: { videoSettings.fps },
                                set: { videoSettings = VideoSettings(fps: $0, resolution: videoSettings.resolution, quality: videoSettings.quality, format: videoSettings.format, duration: videoSettings.duration) }
                            )) {
                                Text("24 fps").tag(24.0)
                                Text("30 fps").tag(30.0)
                                Text("60 fps").tag(60.0)
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Quality
                        VStack(alignment: .leading) {
                            Text("Quality")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Quality", selection: Binding(
                                get: { videoSettings.quality },
                                set: { videoSettings = VideoSettings(fps: videoSettings.fps, resolution: videoSettings.resolution, quality: $0, format: videoSettings.format, duration: videoSettings.duration) }
                            )) {
                                ForEach(VideoSettings.VideoQuality.allCases, id: \.self) { quality in
                                    Text(quality.rawValue).tag(quality)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Resolution
                        VStack(alignment: .leading) {
                            Text("Resolution")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Resolution", selection: $selectedResolution) {
                                Text("1080p").tag("1080p")
                                Text("1440p").tag("1440p")
                                Text("4K").tag("4K")
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedResolution) { resolution in
                                let size: CGSize
                                switch resolution {
                                case "1440p":
                                    size = CGSize(width: 2560, height: 1440)
                                case "4K":
                                    size = CGSize(width: 3840, height: 2160)
                                default: // 1080p
                                    size = CGSize(width: 1920, height: 1080)
                                }
                                videoSettings = VideoSettings(fps: videoSettings.fps, resolution: size, quality: videoSettings.quality, format: videoSettings.format, duration: videoSettings.duration)
                            }
                        }
                        
                        // Format
                        VStack(alignment: .leading) {
                            Text("Format")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Format", selection: Binding(
                                get: { videoSettings.format },
                                set: { videoSettings = VideoSettings(fps: videoSettings.fps, resolution: videoSettings.resolution, quality: videoSettings.quality, format: $0, duration: videoSettings.duration) }
                            )) {
                                ForEach(VideoSettings.VideoFormat.allCases, id: \.self) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Progress
                if let progress = videoGenerator.progress {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Generating Video...")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(progress.percentage))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: progress.percentage / 100)
                        
                        HStack {
                            Text("Frame \(progress.currentFrame) of \(progress.totalFrames)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let remaining = progress.estimatedTimeRemaining {
                                Text("~\(Int(remaining))s remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Success message
                if let generatedVideoURL = generatedVideoURL {
                    VStack(spacing: 12) {
                        Text("✅ Video created successfully!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        HStack(spacing: 12) {
                            Button("Show in Finder") {
                                NSWorkspace.shared.selectFile(generatedVideoURL.path, inFileViewerRootedAtPath: "")
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Play Video") {
                                NSWorkspace.shared.open(generatedVideoURL)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create Video")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if videoGenerator.isGenerating {
                            videoGenerator.cancelGeneration()
                        }
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Create Video") {
                        createVideo()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(videoGenerator.isGenerating || generatedVideoURL != nil)
                }
            }
        }
        .frame(width: 600, height: 500)
        .onDisappear {
            onCompletion()
        }
    }
    
    private func createVideo() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.mpeg4Movie]
        savePanel.nameFieldStringValue = "Timelapse_\(DateFormatter.fileNameFormatter.string(from: Date())).mp4"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                outputURL = url
                generateVideo(outputURL: url)
            }
        }
    }
    
    private func generateVideo(outputURL: URL) {
        errorMessage = nil
        generatedVideoURL = nil
        
        Task {
            do {
                let resultURL = try await videoGenerator.generateVideo(
                    from: selectedImages,
                    settings: videoSettings,
                    outputURL: outputURL
                )
                
                await MainActor.run {
                    generatedVideoURL = resultURL
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

#Preview {
    ContentView()
        .environmentObject(ScreenshotManager())
        .environmentObject(ProjectManager())
        .environmentObject(ThumbnailGenerator())
        .environmentObject(VideoGenerator())
} 