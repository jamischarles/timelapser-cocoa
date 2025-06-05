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
    
    // MARK: - Private Properties
    private var captureTimer: Timer?
    private var countdownTimer: Timer?
    private let captureQueue = DispatchQueue(label: "screenshot.capture", qos: .userInitiated)
    private let fileQueue = DispatchQueue(label: "screenshot.file", qos: .utility)
    
    // Capture settings
    @AppStorage("captureInterval") private var captureInterval: Double = 5.0
    private var currentProject: URL?
    
    // Performance tracking
    private var captureStartTime: Date?
    private var lastCaptureDate: Date?
    
    // MARK: - Initialization
    init() {
        checkPermissions()
    }
    
    // MARK: - Permission Management
    func checkPermissions() {
        hasPermission = CGPreflightScreenCaptureAccess()
        print(hasPermission ? "✅ Screen recording permission granted" : "⚠️ Screen recording permission not granted")
    }
    
    func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Capture Control
    func startCapture() async {
        guard hasPermission else {
            print("❌ Cannot start capture: No screen recording permission")
            return
        }
        
        isCapturing = true
        screenshotCount = 0
        captureStartTime = Date()
        print("🎬 Starting screenshot capture (interval: \(captureInterval)s)")
        
        // Start capture timer
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.captureScreenshot()
            }
        }
        
        // Take first screenshot immediately
        await captureScreenshot()
    }
    
    func stopCapture() async {
        guard isCapturing else { return }
        
        isCapturing = false
        captureTimer?.invalidate()
        captureTimer = nil
        
        let duration = Date().timeIntervalSince(captureStartTime ?? Date())
        captureRate = Double(screenshotCount) / duration
        
        print("🛑 Stopped capture. Screenshots: \(screenshotCount), Duration: \(String(format: "%.1f", duration))s")
    }
    
    // MARK: - Screenshot Capture
    private func captureScreenshot() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Use Core Graphics for ultra-fast screen capture
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            print("❌ Screenshot capture failed")
            return
        }
        
        // Update performance metrics
        lastCaptureTime = CFAbsoluteTimeGetCurrent() - startTime
        screenshotCount += 1
        lastCaptureDate = Date()
        
        print("📸 Screenshot \(screenshotCount) captured in \(String(format: "%.0f", lastCaptureTime * 1000))ms")
        
        // TODO: Save to disk and generate thumbnail (next tasks)
    }
}
