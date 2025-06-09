//
//  VideoGenerator.swift
//  TimelapseCreator
//
//  Created by AI Assistant on 1/6/25.
//  Copyright © 2025 Timelapse Creator. All rights reserved.
//

import SwiftUI
import AVFoundation
import CoreImage
import CoreMedia
import VideoToolbox

// MARK: - Video Generation Settings
struct VideoSettings {
    let fps: Double
    let resolution: CGSize
    let quality: VideoQuality
    let format: VideoFormat
    let duration: TimeInterval? // Optional duration limit
    
    // Advanced pacing controls
    let pacingMode: PacingMode
    let frameSkipPattern: FrameSkipPattern?
    let speedZones: [SpeedZone]
    let frameRepetitions: [FrameRepetition]
    
    enum PacingMode: String, CaseIterable {
        case uniform = "Uniform"
        case variable = "Variable"
        case speedRamp = "Speed Ramp"
        case manual = "Manual"
        
        var description: String {
            switch self {
            case .uniform:
                return "All frames play at the same speed"
            case .variable:
                return "Different sections can have different speeds"
            case .speedRamp:
                return "Gradually changes speed from slow to fast to slow"
            case .manual:
                return "Manually control how long each frame displays"
            }
        }
    }
    
    enum VideoQuality: String, CaseIterable {
        case low = "Low"
        case medium = "Medium" 
        case high = "High"
        case ultra = "Ultra"
        
        var bitRate: Int {
            switch self {
            case .low: return 2_000_000      // 2 Mbps
            case .medium: return 5_000_000   // 5 Mbps
            case .high: return 10_000_000    // 10 Mbps
            case .ultra: return 20_000_000   // 20 Mbps
            }
        }
        
        var codecProfile: String {
            switch self {
            case .low: return AVVideoProfileLevelH264Baseline41
            case .medium: return AVVideoProfileLevelH264Main41
            case .high: return AVVideoProfileLevelH264High41
            case .ultra: return AVVideoProfileLevelH264HighAutoLevel
            }
        }
    }
    
    enum VideoFormat: String, CaseIterable {
        case mp4 = "MP4"
        case mov = "MOV"
        
        var fileType: AVFileType {
            switch self {
            case .mp4: return .mp4
            case .mov: return .mov
            }
        }
        
        var pathExtension: String {
            switch self {
            case .mp4: return "mp4"
            case .mov: return "mov"
            }
        }
    }
    
    static let `default` = VideoSettings(
        fps: 30.0,
        resolution: CGSize(width: 1920, height: 1080),
        quality: .high,
        format: .mp4,
        duration: nil,
        pacingMode: .uniform,
        frameSkipPattern: nil,
        speedZones: [],
        frameRepetitions: []
    )
}

// MARK: - Frame Pacing Models
struct FrameSkipPattern: Hashable, Equatable {
    let skipEveryNFrames: Int
    let keepFrameCount: Int
    
    static let skipHalf = FrameSkipPattern(skipEveryNFrames: 2, keepFrameCount: 1)
    static let skipTwoThirds = FrameSkipPattern(skipEveryNFrames: 3, keepFrameCount: 1)
    static let keepEveryFifth = FrameSkipPattern(skipEveryNFrames: 5, keepFrameCount: 1)
}

struct SpeedZone: Hashable, Equatable {
    let startFrame: Int
    let endFrame: Int
    let speedMultiplier: Double
    
    var description: String {
        return "Frames \(startFrame)-\(endFrame): \(String(format: "%.1f", speedMultiplier))x speed"
    }
}

struct FrameRepetition: Hashable, Equatable {
    let frameIndex: Int
    let repetitionCount: Int
    
    var description: String {
        return "Frame \(frameIndex): repeat \(repetitionCount) time\(repetitionCount == 1 ? "" : "s")"
    }
}

// MARK: - Video Generation Progress
struct VideoGenerationProgress {
    let currentFrame: Int
    let totalFrames: Int
    let elapsedTime: TimeInterval
    let estimatedTimeRemaining: TimeInterval?
    let outputFileSize: Int64
    
    var percentage: Double {
        guard totalFrames > 0 else { return 0 }
        return Double(currentFrame) / Double(totalFrames) * 100
    }
    
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: outputFileSize, countStyle: .file)
    }
}

// MARK: - Video Generator Errors
enum VideoGenerationError: LocalizedError {
    case noImages
    case invalidImageData
    case unsupportedResolution
    case writerCreationFailed
    case inputCreationFailed
    case writingFailed(Error)
    case cancelled
    case insufficientDiskSpace
    
    var errorDescription: String? {
        switch self {
        case .noImages:
            return "No images provided for video generation"
        case .invalidImageData:
            return "Unable to load image data"
        case .unsupportedResolution:
            return "Unsupported video resolution"
        case .writerCreationFailed:
            return "Failed to create video writer"
        case .inputCreationFailed:
            return "Failed to create video input"
        case .writingFailed(let error):
            return "Video writing failed: \(error.localizedDescription)"
        case .cancelled:
            return "Video generation was cancelled"
        case .insufficientDiskSpace:
            return "Insufficient disk space for video generation"
        }
    }
}

// MARK: - Video Generator
@MainActor
class VideoGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var progress: VideoGenerationProgress?
    @Published var lastGenerationTime: TimeInterval = 0
    @Published var generationSpeed: Double = 0 // frames per second during generation
    
    private var generationTask: Task<Void, Never>?
    private var startTime: Date?
    
    // Performance tracking
    private let performanceQueue = DispatchQueue(label: "video.performance", qos: .utility)
    
    func generateVideo(
        from imageURLs: [URL],
        settings: VideoSettings,
        outputURL: URL,
        progressHandler: @escaping (VideoGenerationProgress) -> Void = { _ in }
    ) async throws -> URL {
        
        guard !imageURLs.isEmpty else {
            throw VideoGenerationError.noImages
        }
        
        // Check disk space
        try checkDiskSpace(for: outputURL, estimatedSize: estimateVideoSize(imageCount: imageURLs.count, settings: settings))
        
        isGenerating = true
        startTime = Date()
        progress = VideoGenerationProgress(
            currentFrame: 0,
            totalFrames: imageURLs.count,
            elapsedTime: 0,
            estimatedTimeRemaining: nil,
            outputFileSize: 0
        )
        
        defer {
            isGenerating = false
            if let startTime = startTime {
                lastGenerationTime = Date().timeIntervalSince(startTime)
            }
            progress = nil
        }
        
        do {
            return try await generateVideoInternal(
                imageURLs: imageURLs,
                settings: settings,
                outputURL: outputURL,
                progressHandler: progressHandler
            )
        } catch {
            throw VideoGenerationError.writingFailed(error)
        }
    }
    
    func cancelGeneration() {
        generationTask?.cancel()
        isGenerating = false
        progress = nil
    }
    
    // MARK: - Internal Video Generation
    private func generateVideoInternal(
        imageURLs: [URL],
        settings: VideoSettings,
        outputURL: URL,
        progressHandler: @escaping (VideoGenerationProgress) -> Void
    ) async throws -> URL {
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        // Create asset writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: settings.format.fileType)
        
        // Configure video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(settings.resolution.width),
            AVVideoHeightKey: Int(settings.resolution.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: settings.quality.bitRate,
                AVVideoProfileLevelKey: settings.quality.codecProfile,
                AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                AVVideoExpectedSourceFrameRateKey: settings.fps,
                AVVideoAllowFrameReorderingKey: false // Better for real-time encoding
            ]
        ]
        
        // Create video input
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        // Create pixel buffer adaptor
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: Int(settings.resolution.width),
            kCVPixelBufferHeightKey as String: Int(settings.resolution.height),
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )
        
        guard writer.canAdd(videoInput) else {
            throw VideoGenerationError.inputCreationFailed
        }
        
        writer.add(videoInput)
        
        // Start writing
        guard writer.startWriting() else {
            throw VideoGenerationError.writerCreationFailed
        }
        
        writer.startSession(atSourceTime: .zero)
        
        // Process images
        var frameIndex = 0
        let startTime = Date()
        
        // Generate frame sequence with pacing controls
        let frameSequence = generateFrameSequence(from: imageURLs, settings: settings)
        
        return try await withCheckedThrowingContinuation { continuation in
            generationTask = Task {
                do {
                    var currentTime = CMTime.zero
                    
                    for frameInfo in frameSequence {
                        // Check for cancellation
                        if Task.isCancelled {
                            writer.cancelWriting()
                            continuation.resume(throwing: VideoGenerationError.cancelled)
                            return
                        }
                        
                        // Wait for input to be ready
                        while !videoInput.isReadyForMoreMediaData {
                            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        }
                        
                        // Load and process image
                        guard let image = NSImage(contentsOf: frameInfo.imageURL),
                              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                            continue // Skip invalid images
                        }
                        
                        // Create pixel buffer
                        guard let pixelBuffer = createPixelBuffer(from: cgImage, size: settings.resolution, adaptor: adaptor) else {
                            continue
                        }
                        
                        // Append pixel buffer with custom duration
                        if !adaptor.append(pixelBuffer, withPresentationTime: currentTime) {
                            print("⚠️ Failed to append frame \(frameIndex)")
                        }
                        
                        // Advance time by frame duration
                        currentTime = CMTimeAdd(currentTime, frameInfo.duration)
                        frameIndex += 1
                        
                        // Update progress
                        let elapsed = Date().timeIntervalSince(startTime)
                        let estimated = frameIndex > 0 ? (elapsed / Double(frameIndex)) * Double(frameSequence.count - frameIndex) : nil
                        let fileSize = getFileSize(at: outputURL)
                        
                        let currentProgress = VideoGenerationProgress(
                            currentFrame: frameIndex,
                            totalFrames: frameSequence.count,
                            elapsedTime: elapsed,
                            estimatedTimeRemaining: estimated,
                            outputFileSize: fileSize
                        )
                        
                        await MainActor.run {
                            self.progress = currentProgress
                            self.generationSpeed = Double(frameIndex) / elapsed
                        }
                        
                        progressHandler(currentProgress)
                    }
                    
                    // Finish writing
                    videoInput.markAsFinished()
                    
                    await writer.finishWriting()
                    
                    if writer.status == .completed {
                        await MainActor.run {
                            continuation.resume(returning: outputURL)
                        }
                    } else {
                        await MainActor.run {
                            continuation.resume(throwing: VideoGenerationError.writingFailed(writer.error ?? NSError(domain: "VideoGeneration", code: -1)))
                        }
                    }
                    
                } catch {
                    writer.cancelWriting()
                    await MainActor.run {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Frame Sequence Generation
    private struct FrameInfo {
        let imageURL: URL
        let duration: CMTime
        let originalIndex: Int
    }
    
    private func generateFrameSequence(from imageURLs: [URL], settings: VideoSettings) -> [FrameInfo] {
        var sequence: [FrameInfo] = []
        let baseDuration = CMTime(value: 1, timescale: CMTimeScale(settings.fps))
        
        switch settings.pacingMode {
        case .uniform:
            // Standard uniform pacing
            sequence = imageURLs.enumerated().compactMap { index, url in
                if shouldIncludeFrame(index: index, pattern: settings.frameSkipPattern) {
                    return FrameInfo(imageURL: url, duration: baseDuration, originalIndex: index)
                }
                return nil
            }
            
        case .variable:
            // Variable pacing based on speed zones
            sequence = generateVariablePacingSequence(imageURLs: imageURLs, settings: settings, baseDuration: baseDuration)
            
        case .speedRamp:
            // Gradual speed changes
            sequence = generateSpeedRampSequence(imageURLs: imageURLs, settings: settings, baseDuration: baseDuration)
            
        case .manual:
            // Manual frame repetitions
            sequence = generateManualSequence(imageURLs: imageURLs, settings: settings, baseDuration: baseDuration)
        }
        
        return sequence
    }
    
    private func shouldIncludeFrame(index: Int, pattern: FrameSkipPattern?) -> Bool {
        guard let pattern = pattern else { return true }
        
        let cyclePosition = index % pattern.skipEveryNFrames
        return cyclePosition < pattern.keepFrameCount
    }
    
    private func generateVariablePacingSequence(imageURLs: [URL], settings: VideoSettings, baseDuration: CMTime) -> [FrameInfo] {
        var sequence: [FrameInfo] = []
        
        for (index, url) in imageURLs.enumerated() {
            guard shouldIncludeFrame(index: index, pattern: settings.frameSkipPattern) else { continue }
            
            // Find applicable speed zone
            let speedMultiplier = settings.speedZones.first { zone in
                index >= zone.startFrame && index <= zone.endFrame
            }?.speedMultiplier ?? 1.0
            
            // Adjust duration based on speed multiplier (inverse relationship)
            let adjustedDuration = CMTime(
                value: baseDuration.value,
                timescale: CMTimeScale(Double(baseDuration.timescale) * speedMultiplier)
            )
            
            sequence.append(FrameInfo(imageURL: url, duration: adjustedDuration, originalIndex: index))
        }
        
        return sequence
    }
    
    private func generateSpeedRampSequence(imageURLs: [URL], settings: VideoSettings, baseDuration: CMTime) -> [FrameInfo] {
        var sequence: [FrameInfo] = []
        let totalFrames = imageURLs.count
        
        for (index, url) in imageURLs.enumerated() {
            guard shouldIncludeFrame(index: index, pattern: settings.frameSkipPattern) else { continue }
            
            // Create a speed ramp: slow at start, fast in middle, slow at end
            let progress = Double(index) / Double(totalFrames - 1)
            let speedMultiplier = 0.5 + 1.5 * sin(progress * .pi) // Creates a sine wave from 0.5x to 2x speed
            
            let adjustedDuration = CMTime(
                value: baseDuration.value,
                timescale: CMTimeScale(Double(baseDuration.timescale) * speedMultiplier)
            )
            
            sequence.append(FrameInfo(imageURL: url, duration: adjustedDuration, originalIndex: index))
        }
        
        return sequence
    }
    
    private func generateManualSequence(imageURLs: [URL], settings: VideoSettings, baseDuration: CMTime) -> [FrameInfo] {
        var sequence: [FrameInfo] = []
        
        for (index, url) in imageURLs.enumerated() {
            guard shouldIncludeFrame(index: index, pattern: settings.frameSkipPattern) else { continue }
            
            sequence.append(FrameInfo(imageURL: url, duration: baseDuration, originalIndex: index))
            
            // Add repetitions for this frame
            let repetition = settings.frameRepetitions.first { $0.frameIndex == index }
            if let rep = repetition {
                for _ in 0..<rep.repetitionCount {
                    sequence.append(FrameInfo(imageURL: url, duration: baseDuration, originalIndex: index))
                }
            }
        }
        
        return sequence
    }
    
    // MARK: - Helper Methods
    private func createPixelBuffer(from cgImage: CGImage, size: CGSize, adaptor: AVAssetWriterInputPixelBufferAdaptor) -> CVPixelBuffer? {
        guard let pixelBufferPool = adaptor.pixelBufferPool else {
            return nil
        }
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        // Fill with black background
        context.setFillColor(CGColor.black)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Scale image to fit while maintaining aspect ratio
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scaledRect = scaleRectToFit(imageSize: imageSize, targetSize: size)
        
        context.draw(cgImage, in: scaledRect)
        
        return buffer
    }
    
    private func scaleRectToFit(imageSize: CGSize, targetSize: CGSize) -> CGRect {
        let aspectRatio = imageSize.width / imageSize.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        let scaledSize: CGSize
        if aspectRatio > targetAspectRatio {
            // Image is wider - scale by width
            scaledSize = CGSize(
                width: targetSize.width,
                height: targetSize.width / aspectRatio
            )
        } else {
            // Image is taller - scale by height
            scaledSize = CGSize(
                width: targetSize.height * aspectRatio,
                height: targetSize.height
            )
        }
        
        let origin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )
        
        return CGRect(origin: origin, size: scaledSize)
    }
    
    private func checkDiskSpace(for url: URL, estimatedSize: Int64) throws {
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: url.deletingLastPathComponent().path)
        let freeSpace = attributes[.systemFreeSize] as? Int64 ?? 0
        
        if freeSpace < estimatedSize * 2 { // Require 2x estimated size for safety
            throw VideoGenerationError.insufficientDiskSpace
        }
    }
    
    private func estimateVideoSize(imageCount: Int, settings: VideoSettings) -> Int64 {
        // Rough estimation: bitrate * duration / 8 (convert bits to bytes)
        let duration = Double(imageCount) / settings.fps
        let estimatedSize = Int64(Double(settings.quality.bitRate) * duration / 8)
        return estimatedSize
    }
    
    private func getFileSize(at url: URL) -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return 0
        }
        return attributes[.size] as? Int64 ?? 0
    }
}

// MARK: - Preview Support
extension VideoGenerator {
    static let shared = VideoGenerator()
} 