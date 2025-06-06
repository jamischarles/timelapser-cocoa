//
//  ScreenshotManager.swift
//  TimelapseCreator
//
//  Created by AI Assistant on 1/6/25.
//  Copyright © 2025 Timelapse Creator. All rights reserved.
//

import SwiftUI
import CoreGraphics
import AppKit
import Combine

@MainActor
class ScreenshotManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isCapturing = false
    @Published var hasPermission = false
    @Published var screenshotCount = 0
    @Published var timeUntilNextCapture: Double = 0
    @Published var captureRate: Double = 0
    @Published var lastCaptureTime: Double = 0
    
    // Window and region selection
    @Published var availableWindows: [(id: CGWindowID, name: String, ownerName: String)] = []
    @Published var selectedWindowID: CGWindowID = 0
    @Published var customRegion: CGRect = .zero
    @Published var isSelectingRegion = false
    
    // Expose capture area mode for UI binding
    var captureAreaMode: Int {
        get { _captureAreaMode }
        set { 
            _captureAreaMode = newValue
            setCaptureAreaMode(newValue)
        }
    }
    private var _captureAreaMode: Int = 0
    
    // MARK: - Private Properties
    private var captureTimer: Timer?
    private var countdownTimer: Timer?
    private let captureQueue = DispatchQueue(label: "screenshot.capture", qos: .userInitiated)
    private let fileQueue = DispatchQueue(label: "screenshot.file", qos: .utility)
    
    // Capture settings
    @AppStorage("captureInterval") private var captureInterval: Double = 5.0
    @AppStorage("selectedDisplayID") private var selectedDisplayID: Int = 0
    @AppStorage("captureAreaMode") private var storedCaptureAreaMode: Int = 0 // 0 = full screen, 1 = main display, 2 = specific window, 3 = custom region
    @AppStorage("imageQuality") private var imageQuality: Double = 0.7 // Reduced from 0.8 to balance quality vs file size
    @AppStorage("imageFormat") private var imageFormat: Int = 1 // 0 = PNG, 1 = JPEG (Default to JPEG for smaller files)
    
    // Connection to ProjectManager
    private weak var projectManager: ProjectManager?
    
    // Display management
    private var availableDisplays: [CGDirectDisplayID] = []
    
    // Performance tracking
    private var captureStartTime: Date?
    private var lastCaptureDate: Date?
    
    // Thumbnail generation
    private var thumbnailGenerator: ThumbnailGenerator?
    
    // MARK: - Initialization
    init() {
        // Initialize capture area mode from stored value
        _captureAreaMode = storedCaptureAreaMode
        
        // Check permissions on main actor to ensure @Published property updates correctly
        Task { @MainActor in
            checkPermissions()
        }
        detectDisplays()
    }
    
    // Method to set thumbnail generator (called from ContentView)
    func setThumbnailGenerator(_ generator: ThumbnailGenerator) {
        thumbnailGenerator = generator
    }
    
    // Method to set project manager connection
    func setProjectManager(_ manager: ProjectManager) {
        projectManager = manager
    }
    
    // MARK: - Permission Management
    @MainActor
    func checkPermissions() {
        let preflightResult = CGPreflightScreenCaptureAccess()
        print("🔍 CGPreflightScreenCaptureAccess() returned: \(preflightResult)")
        
        // Try a more sophisticated check for development builds
        if preflightResult {
            hasPermission = true
            print("✅ Screen recording permission detected as granted via preflight")
        } else {
            // For development, try checking if we can actually capture
            // This uses a different approach that's less likely to trigger dialogs
            let testResult = canCaptureWithoutDialog()
            hasPermission = testResult
            print(testResult ? "✅ Screen recording permission detected via test capture" : "⚠️ Screen recording permission not detected")
        }
    }
    
    private func canCaptureWithoutDialog() -> Bool {
        // Use a simpler approach for development builds
        // Try to get display bounds which is usually accessible
        print("🔍 Testing screen capture capability...")
        
        let mainDisplay = CGMainDisplayID()
        let bounds = CGDisplayBounds(mainDisplay)
        
        // If we can get valid display info, permissions are likely granted
        let hasValidBounds = bounds.width > 0 && bounds.height > 0
        print("🔍 Display bounds check: \(hasValidBounds ? "valid" : "invalid")")
        
        // Additional check - try to see if we can get window list without triggering dialogs
        let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
        let hasWindowList = windowList != nil
        print("🔍 Window list check: \(hasWindowList ? "valid" : "invalid")")
        
        return hasValidBounds && hasWindowList
    }
    
    func requestPermissions() async {
        // First check if we already have permission
        let currentPermission = CGPreflightScreenCaptureAccess()
        
        await MainActor.run {
            hasPermission = currentPermission
        }
        
        if currentPermission {
            print("✅ Screen recording permission already granted - no dialog needed")
            return
        }
        
        print("🔑 Screen recording permission not detected.")
        print("🔑 Please manually grant permission in System Preferences > Security & Privacy > Privacy > Screen Recording")
        
        // Don't trigger any screen capture APIs that would show unwanted permission dialogs
        // Instead, direct user to manually enable permissions in System Preferences
        // The actual permission dialog will only appear when they start capturing
    }
    
    func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
    
    func resetPermissions() async {
        print("🔄 Resetting permissions...")
        
        // Clear any cached permission state
        await MainActor.run {
            hasPermission = false
        }
        
        // Force a new permission check by actually attempting a capture
        // This is the most reliable way to trigger the system permission dialog
        print("🔑 Forcing permission dialog by attempting capture...")
        
        // Try to capture screen - this will trigger the system permission dialog if needed
        let result = await withCheckedContinuation { continuation in
            captureQueue.async {
                // This call will trigger the macOS permission dialog if permission hasn't been granted
                let testImage = CGDisplayCreateImage(CGMainDisplayID())
                let success = testImage != nil
                continuation.resume(returning: success)
            }
        }
        
        await MainActor.run {
            hasPermission = result
            if result {
                print("✅ Permissions granted after reset")
            } else {
                print("⚠️ Permissions still not granted - user may need to approve dialog")
            }
        }
    }
    
    // MARK: - Display Management
    private func detectDisplays() {
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)
        
        if displayCount > 0 {
            availableDisplays = Array(repeating: 0, count: Int(displayCount))
            CGGetActiveDisplayList(displayCount, &availableDisplays, &displayCount)
            
            print("🖥️ Detected \(displayCount) display(s)")
            
            // Set default to main display if none selected
            if selectedDisplayID == 0 && !availableDisplays.isEmpty {
                selectedDisplayID = Int(CGMainDisplayID())
            }
        }
    }
    
    // MARK: - Window Management
    @MainActor
    func detectWindows() {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            print("❌ Failed to get window list")
            return
        }
        
        availableWindows = windowList.compactMap { windowInfo in
            guard let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
                  let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                  let windowName = windowInfo[kCGWindowName as String] as? String,
                  !windowName.isEmpty,
                  ownerName != "TimelapseCreator" // Exclude our own app
            else { return nil }
            
            return (id: windowID, name: windowName, ownerName: ownerName)
        }
        
        print("🪟 Detected \(availableWindows.count) windows")
    }
    
    func setSelectedWindow(_ windowID: CGWindowID) {
        selectedWindowID = windowID
        print("🪟 Selected window ID: \(windowID)")
    }
    
    func setCustomRegion(_ region: CGRect) {
        customRegion = region
        print("🔲 Custom region set: \(region)")
    }
    
    func getDisplayInfo() -> [(id: CGDirectDisplayID, name: String, bounds: CGRect)] {
        return availableDisplays.map { displayID in
            let bounds = CGDisplayBounds(displayID)
            let name = getDisplayName(displayID)
            return (id: displayID, name: name, bounds: bounds)
        }
    }
    
    private func getDisplayName(_ displayID: CGDirectDisplayID) -> String {
        if displayID == CGMainDisplayID() {
            return "Main Display"
        } else {
            return "Display \(displayID)"
        }
    }
    
    private func getCombinedDisplayBounds() -> CGRect {
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
    
    // MARK: - Capture Configuration
    func setDisplayID(_ displayID: CGDirectDisplayID) {
        selectedDisplayID = Int(displayID)
        print("🖥️ Selected display: \(getDisplayName(displayID))")
    }
    
    func setCaptureAreaMode(_ mode: Int) {
        _captureAreaMode = mode
        storedCaptureAreaMode = mode
        let modeDescription = switch mode {
        case 0: "Full Screen"
        case 1: "Main Display" 
        case 2: "Specific Window"
        case 3: "Custom Region"
        default: "Unknown"
        }
        print("📱 Capture mode: \(modeDescription)")
        
        // Refresh windows when switching to window mode
        if mode == 2 {
            Task { @MainActor in
                detectWindows()
            }
        }
    }
    
    func setImageFormat(_ format: Int, quality: Double = 0.8) {
        imageFormat = format
        imageQuality = quality
        let formatDescription = format == 0 ? "PNG" : "JPEG"
        print("🖼️ Image format: \(formatDescription) (quality: \(String(format: "%.1f", quality * 100))%)")
    }
    
    // MARK: - Capture Control
    func startCapture() async {
        print("🚀 startCapture() called - hasPermission: \(hasPermission)")
        
        guard hasPermission else {
            print("❌ Cannot start capture: No screen recording permission")
            return
        }
        
        isCapturing = true
        screenshotCount = 0
        captureStartTime = Date()
        lastCaptureDate = Date() // Set immediately so countdown timer works
        print("🎬 Starting screenshot capture (interval: \(captureInterval)s)")
        print("🎬 Current project: \(projectManager?.currentProject?.name ?? "nil")")
        
        // Start capture timer
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.captureScreenshot()
            }
        }
        
        // Start countdown timer for UI updates
        timeUntilNextCapture = captureInterval
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.updateCountdown()
            }
        }
        
        // Take first screenshot immediately
        await captureScreenshot()
    }
    
    func stopCapture() async {
        guard isCapturing else { return }
        
        isCapturing = false
        captureTimer?.invalidate()
        countdownTimer?.invalidate()
        captureTimer = nil
        countdownTimer = nil
        
        let duration = Date().timeIntervalSince(captureStartTime ?? Date())
        captureRate = Double(screenshotCount) / duration
        
        print("🛑 Stopped capture. Screenshots: \(screenshotCount), Duration: \(String(format: "%.1f", duration))s, Rate: \(String(format: "%.2f", captureRate)) fps")
    }
    
    // MARK: - Screenshot Capture
    private func captureScreenshot() async {
        print("📸 captureScreenshot() started")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Add a small delay to ensure UI state is stable
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            
            // Capture screenshot on background queue for optimal performance
            let screenshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
                captureQueue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume(throwing: ScreenshotError.captureFailure)
                        return
                    }
                    print("📸 Attempting screen capture...")
                    
                    // Perform capture synchronously on background queue
                    let result = self.performScreenCaptureSync()
                    print("📸 Screen capture result: \(result)")
                    continuation.resume(with: result)
                }
            }
            
            print("📸 Screenshot captured successfully")
            
            // Ensure we have a project directory
            if projectManager?.currentProject == nil {
                print("📁 No current project, creating new one...")
                await createCaptureProject()
            }
            
            // Save to disk on file queue
            if let projectURL = projectManager?.currentProject?.url {
                print("💾 Saving screenshot to: \(projectURL.path)")
                await saveScreenshot(screenshot, to: projectURL)
            } else {
                print("❌ No project URL available for saving")
            }
            
            // Update performance metrics
            await MainActor.run {
                lastCaptureTime = CFAbsoluteTimeGetCurrent() - startTime
                screenshotCount += 1
                lastCaptureDate = Date()
                
                print("📸 Screenshot \(screenshotCount) captured in \(String(format: "%.0f", lastCaptureTime * 1000))ms")
            }
            
        } catch {
            print("❌ Screenshot capture failed: \(error.localizedDescription)")
            await handleCaptureError(error)
        }
    }
    
    private func performScreenCaptureSync() -> Result<CGImage, Error> {
        var cgImage: CGImage?
        
        switch _captureAreaMode {
        case 0: // Full screen (all displays)
            print("🎯 Full screen capture using Core Graphics")
            // Try multiple approaches to capture all displays
            
            // First attempt: Use CGRect.infinite to capture all displays
            cgImage = CGWindowListCreateImage(
                CGRect.infinite,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            )
            
            // Fallback: If infinite rect doesn't work, calculate combined display bounds
            if cgImage == nil {
                print("⚠️ Infinite rect capture failed, trying combined display bounds...")
                let combinedBounds = getCombinedDisplayBounds()
                cgImage = CGWindowListCreateImage(
                    combinedBounds,
                    .optionOnScreenOnly,
                    kCGNullWindowID,
                    .bestResolution
                )
            }
            
            // Final fallback: Use main display capture
            if cgImage == nil {
                print("⚠️ Combined bounds capture failed, falling back to main display...")
                cgImage = CGDisplayCreateImage(CGMainDisplayID())
            }

        case 1: // Main display only
            let displayID = selectedDisplayID == 0 ? CGMainDisplayID() : CGDirectDisplayID(selectedDisplayID)
            cgImage = CGDisplayCreateImage(displayID)
            
        case 2: // Specific window
            if selectedWindowID != 0 {
                cgImage = CGWindowListCreateImage(
                    .null,
                    .optionIncludingWindow,
                    selectedWindowID,
                    .bestResolution
                )
            } else {
                // Fallback to full screen if no window selected
                cgImage = CGWindowListCreateImage(
                    .null,
                    .optionOnScreenOnly,
                    kCGNullWindowID,
                    .bestResolution
                )
            }
            
        case 3: // Custom region
            if !customRegion.isEmpty {
                cgImage = CGWindowListCreateImage(
                    customRegion,
                    .optionOnScreenOnly,
                    kCGNullWindowID,
                    .bestResolution
                )
            } else {
                // Fallback to full screen if no region selected
                cgImage = CGWindowListCreateImage(
                    .null,
                    .optionOnScreenOnly,
                    kCGNullWindowID,
                    .bestResolution
                )
            }
            
        default: // Fallback to full screen
            cgImage = CGWindowListCreateImage(
                .null,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            )
        }
        
        guard let image = cgImage else {
            return .failure(ScreenshotError.captureFailure)
        }
        
        // Validate image dimensions for memory safety
        let width = image.width
        let height = image.height
        
        guard width > 0 && height > 0 && width <= 16384 && height <= 16384 else {
            return .failure(ScreenshotError.invalidDimensions)
        }
        
        print("📐 Captured image: \(width)×\(height) pixels")
        
        return .success(image)
    }
    

    
    private func saveScreenshot(_ image: CGImage, to projectURL: URL) async {
        // Capture main actor properties before background work
        let currentImageFormat = imageFormat
        let currentImageQuality = imageQuality
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            fileQueue.async {
                let saveStartTime = CFAbsoluteTimeGetCurrent()
                
                do {
                    // Generate timestamp-based filename
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd_HHmmss_SSS"
                    let timestamp = formatter.string(from: Date())
                    
                    let fileExtension = currentImageFormat == 0 ? "png" : "jpg"
                    let filename = "screenshot_\(timestamp).\(fileExtension)"
                    let fileURL = projectURL.appendingPathComponent(filename)
                    
                    // Create NSBitmapImageRep for optimized encoding
                    let bitmapRep = NSBitmapImageRep(cgImage: image)
                    bitmapRep.size = NSSize(width: image.width, height: image.height)
                    
                    // Optimize compression based on format and quality settings
                    let imageData: Data?
                    
                    if currentImageFormat == 0 { // PNG
                        imageData = bitmapRep.representation(using: .png, properties: [:])
                    } else { // JPEG
                        let compressionProperties: [NSBitmapImageRep.PropertyKey: Any] = [
                            .compressionFactor: NSNumber(value: Float(currentImageQuality)) // JPEG quality (0.0 = worst, 1.0 = best)
                        ]
                        imageData = bitmapRep.representation(using: .jpeg, properties: compressionProperties)
                    }
                    
                    guard let data = imageData else {
                        print("❌ Failed to encode image data")
                        continuation.resume()
                        return
                    }
                    
                    // Write file atomically for data integrity
                    try data.write(to: fileURL, options: .atomic)
                    
                    let saveTime = CFAbsoluteTimeGetCurrent() - saveStartTime
                    let fileSize = data.count
                    
                    // Use local method for file size formatting
                    let fileSizeStr = ByteCountFormatter().string(fromByteCount: Int64(fileSize))
                    print("💾 Saved \(filename) (\(fileSizeStr)) in \(String(format: "%.0f", saveTime * 1000))ms")
                    
                    // Generate thumbnail asynchronously with low priority to avoid blocking capture
                    Task(priority: .utility) {
                        await self.generateThumbnailAsync(for: fileURL)
                    }
                    
                } catch {
                    print("❌ Failed to save screenshot: \(error.localizedDescription)")
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleCaptureError(_ error: Error) async {
        // Implement retry logic for transient failures
        if case ScreenshotError.captureFailure = error {
            // Wait briefly and retry once
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Single retry attempt
            await captureScreenshot()
        } else {
            // Stop capture on persistent errors
            await stopCapture()
        }
    }
    
    // MARK: - Project Management
    private func createCaptureProject() async {
        print("📁 Delegating project creation to ProjectManager...")
        await MainActor.run {
            projectManager?.createNewProject()
        }
    }
    
    // MARK: - UI Updates
    @MainActor
    private func updateCountdown() async {
        guard isCapturing else { return }
        
        if let lastCapture = lastCaptureDate {
            let elapsed = Date().timeIntervalSince(lastCapture)
            timeUntilNextCapture = max(0, captureInterval - elapsed)
        } else {
            timeUntilNextCapture = captureInterval
        }
    }
    
    // MARK: - Thumbnail Generation
    private func generateThumbnailAsync(for imageURL: URL) async {
        guard let thumbnailGenerator = thumbnailGenerator else {
            print("⚠️ ThumbnailGenerator not available for \(imageURL.lastPathComponent)")
            return
        }
        
        do {
            let _ = try await thumbnailGenerator.generateThumbnail(from: imageURL)
            print("🖼️ Thumbnail generated for \(imageURL.lastPathComponent)")
        } catch {
            print("❌ Failed to generate thumbnail for \(imageURL.lastPathComponent): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Utility Functions
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Error Types
enum ScreenshotError: LocalizedError {
    case permissionDenied
    case captureFailure
    case invalidDimensions
    case fileSystemError
    case compressionFailure
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission required"
        case .captureFailure:
            return "Failed to capture screenshot"
        case .invalidDimensions:
            return "Invalid screenshot dimensions"
        case .fileSystemError:
            return "Unable to save screenshot"
        case .compressionFailure:
            return "Failed to compress image data"
        }
    }
}
