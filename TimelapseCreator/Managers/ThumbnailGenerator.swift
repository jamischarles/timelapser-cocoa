//
//  ThumbnailGenerator.swift
//  TimelapseCreator
//
//  Created by AI Assistant on 1/6/25.
//  Copyright © 2025 Timelapse Creator. All rights reserved.
//

import SwiftUI
import CoreImage
import CoreGraphics
import AppKit

@MainActor
class ThumbnailGenerator: ObservableObject {
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var thumbnailsGenerated = 0
    @Published var averageGenerationTime: Double = 0
    
    // MARK: - Private Properties
    private let context: CIContext
    private let thumbnailQueue = DispatchQueue(label: "thumbnail.generation", qos: .userInitiated, attributes: .concurrent)
    private let fileQueue = DispatchQueue(label: "thumbnail.file", qos: .utility)
    
    // Cache for intelligent memory management
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private let cgImageCache = NSCache<NSString, CGImageWrapper>()
    
    // Performance tracking
    private var generationStartTime: Date?
    private var totalGenerationTime: Double = 0
    
    // Settings
    @AppStorage("thumbnailSize") private var thumbnailSize: Double = 150 // Reduced from 200 for faster generation
    @AppStorage("thumbnailQuality") private var thumbnailQuality: Double = 0.8
    @AppStorage("enableThumbnailCache") private var enableThumbnailCache: Bool = true
    @AppStorage("maxCacheSize") private var maxCacheSize: Int = 100
    
    // MARK: - Initialization
    init() {
        // Create Core Image context optimized for memory efficiency over speed
        let contextOptions: [CIContextOption: Any] = [
            .useSoftwareRenderer: true,   // Use software rendering to reduce system log noise
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB),
            .cacheIntermediates: false    // Don't cache intermediates for memory efficiency
        ]
        
        self.context = CIContext(options: contextOptions)
        
        // Configure caches
        configureCaches()
        
        print("🖼️ ThumbnailGenerator initialized with hardware acceleration")
    }
    
    // MARK: - Cache Configuration
    private func configureCaches() {
        // Configure thumbnail cache
        thumbnailCache.countLimit = maxCacheSize
        thumbnailCache.totalCostLimit = maxCacheSize * Int(thumbnailSize * thumbnailSize * 4) // Estimate memory cost
        
        // Configure CGImage cache (smaller since these are larger)
        cgImageCache.countLimit = maxCacheSize / 2
        cgImageCache.totalCostLimit = cgImageCache.countLimit * (1920 * 1080 * 4) // Estimate for full-size images
        
        print("🗄️ Configured caches: thumbnails=\(maxCacheSize), images=\(cgImageCache.countLimit)")
    }
    
    // MARK: - Single Thumbnail Generation
    func generateThumbnail(from imageURL: URL, targetSize: CGSize? = nil) async throws -> NSImage {
        let startTime = CFAbsoluteTimeGetCurrent()
        let cacheKey = "\(imageURL.lastPathComponent)_\(Int(thumbnailSize))"
        
        // Check cache first
        if enableThumbnailCache, let cachedThumbnail = thumbnailCache.object(forKey: cacheKey as NSString) {
            print("💾 Cache hit for \(imageURL.lastPathComponent)")
            return cachedThumbnail
        }
        
        let size = targetSize ?? CGSize(width: thumbnailSize, height: thumbnailSize)
        
        do {
            // Load and process image on background queue
            let thumbnail = try await withCheckedThrowingContinuation { continuation in
                thumbnailQueue.async {
                    do {
                        let result = try self.processImageToThumbnail(imageURL: imageURL, targetSize: size)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Cache the result if enabled
            if enableThumbnailCache {
                let cost = Int(size.width * size.height * 4) // Estimate memory cost
                thumbnailCache.setObject(thumbnail, forKey: cacheKey as NSString, cost: cost)
            }
            
            // Update performance metrics
            let generationTime = CFAbsoluteTimeGetCurrent() - startTime
            await updatePerformanceMetrics(generationTime)
            
            print("🏎️ Generated thumbnail for \(imageURL.lastPathComponent) in \(String(format: "%.0f", generationTime * 1000))ms")
            
            return thumbnail
            
        } catch {
            print("❌ Failed to generate thumbnail for \(imageURL.lastPathComponent): \(error.localizedDescription)")
            throw ThumbnailError.generationFailed
        }
    }
    
    // MARK: - Batch Thumbnail Generation
    func generateThumbnails(for imageURLs: [URL], targetSize: CGSize? = nil) async throws -> [NSImage] {
        let startTime = Date()
        generationStartTime = startTime
        isGenerating = true
        thumbnailsGenerated = 0
        totalGenerationTime = 0
        generationProgress = 0
        
        let size = targetSize ?? CGSize(width: thumbnailSize, height: thumbnailSize)
        let totalImages = imageURLs.count
        
        print("🚀 Starting batch thumbnail generation for \(totalImages) images")
        
        // Process images in concurrent batches for optimal performance
        let batchSize = min(10, totalImages) // Process up to 10 images concurrently
        var results: [NSImage] = []
        
        for batch in imageURLs.chunked(into: batchSize) {
            // Process batch concurrently
            let batchResults = try await withThrowingTaskGroup(of: (Int, NSImage).self) { group in
                for (index, imageURL) in batch.enumerated() {
                    group.addTask {
                        let thumbnail = try await self.generateThumbnail(from: imageURL, targetSize: size)
                        return (index, thumbnail)
                    }
                }
                
                // Collect results in order
                var batchThumbnails: [(Int, NSImage)] = []
                for try await result in group {
                    batchThumbnails.append(result)
                    
                    // Update progress on main actor
                    await self.updateBatchProgress()
                }
                
                return batchThumbnails.sorted { $0.0 < $1.0 }.map { $0.1 }
            }
            
            results.append(contentsOf: batchResults)
        }
        
        // Final metrics update
        let totalTime = Date().timeIntervalSince(startTime)
        averageGenerationTime = totalTime / Double(totalImages)
        isGenerating = false
        generationProgress = 1.0
        
        print("✅ Batch generation complete: \(totalImages) thumbnails in \(String(format: "%.2f", totalTime))s (avg: \(String(format: "%.0f", averageGenerationTime * 1000))ms)")
        
        return results
    }
    
    // MARK: - Core Image Processing
    private func processImageToThumbnail(imageURL: URL, targetSize: CGSize) throws -> NSImage {
        // Load CGImage from file
        guard let cgImage = loadCGImage(from: imageURL) else {
            throw ThumbnailError.imageLoadFailed
        }
        
        // Create CIImage from CGImage
        let ciImage = CIImage(cgImage: cgImage)
        
        // Calculate scale factor to maintain aspect ratio
        let imageSize = ciImage.extent.size
        let scaleX = targetSize.width / imageSize.width
        let scaleY = targetSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        
        // Apply high-quality scaling using Lanczos filter
        guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
            throw ThumbnailError.filterCreationFailed
        }
        
        scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        guard let scaledImage = scaleFilter.outputImage else {
            throw ThumbnailError.scalingFailed
        }
        
        // Center crop to exact target size if needed
        let scaledSize = scaledImage.extent.size
        let cropRect: CGRect
        
        if scaledSize.width != targetSize.width || scaledSize.height != targetSize.height {
            let x = (scaledSize.width - targetSize.width) / 2
            let y = (scaledSize.height - targetSize.height) / 2
            cropRect = CGRect(x: x, y: y, width: targetSize.width, height: targetSize.height)
        } else {
            cropRect = scaledImage.extent
        }
        
        // Render to CGImage using hardware acceleration
        guard let thumbnailCGImage = context.createCGImage(scaledImage, from: cropRect) else {
            throw ThumbnailError.renderingFailed
        }
        
        // Convert to NSImage
        let thumbnailImage = NSImage(cgImage: thumbnailCGImage, size: targetSize)
        return thumbnailImage
    }
    
    // MARK: - Image Loading
    private func loadCGImage(from url: URL) -> CGImage? {
        let cacheKey = url.lastPathComponent as NSString
        
        // Check CGImage cache first
        if let wrapper = cgImageCache.object(forKey: cacheKey), let cgImage = wrapper.cgImage {
            return cgImage
        }
        
        // Load from file
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        
        // Cache the CGImage
        let wrapper = CGImageWrapper(cgImage: cgImage)
        let cost = cgImage.width * cgImage.height * 4 // Estimate memory cost
        cgImageCache.setObject(wrapper, forKey: cacheKey, cost: cost)
        
        return cgImage
    }
    
    // MARK: - Performance Tracking
    private func updatePerformanceMetrics(_ generationTime: Double) async {
        thumbnailsGenerated += 1
        totalGenerationTime += generationTime
        averageGenerationTime = totalGenerationTime / Double(thumbnailsGenerated)
    }
    
    private func updateBatchProgress() async {
        thumbnailsGenerated += 1
        if let startTime = generationStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > 0 {
                averageGenerationTime = elapsed / Double(thumbnailsGenerated)
            }
        }
        // Progress will be updated by the batch generation method
    }
    
    // MARK: - Cache Management
    func clearCache() {
        thumbnailCache.removeAllObjects()
        cgImageCache.removeAllObjects()
        print("🗑️ Thumbnail cache cleared")
    }
    
    func getCacheStats() -> (thumbnailCount: Int, imageCount: Int, estimatedMemory: String) {
        let thumbnailCount = thumbnailCache.countLimit > 0 ? min(thumbnailsGenerated, thumbnailCache.countLimit) : 0
        let imageCount = cgImageCache.countLimit > 0 ? min(thumbnailsGenerated, cgImageCache.countLimit) : 0
        
        let estimatedBytes = thumbnailCount * Int(thumbnailSize * thumbnailSize * 4) + 
                           imageCount * (1920 * 1080 * 4)
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        let memoryString = formatter.string(fromByteCount: Int64(estimatedBytes))
        
        return (thumbnailCount, imageCount, memoryString)
    }
    
    // MARK: - Settings
    func updateThumbnailSize(_ size: Double) {
        thumbnailSize = size
        clearCache() // Clear cache since thumbnail size changed
        print("📏 Updated thumbnail size to \(Int(size))px")
    }
    
    func updateCacheSettings(enabled: Bool, maxSize: Int) {
        enableThumbnailCache = enabled
        maxCacheSize = maxSize
        configureCaches()
        
        if !enabled {
            clearCache()
        }
        
        print("⚙️ Updated cache settings: enabled=\(enabled), maxSize=\(maxSize)")
    }
}

// MARK: - Supporting Types
class CGImageWrapper {
    let cgImage: CGImage?
    
    init(cgImage: CGImage?) {
        self.cgImage = cgImage
    }
}

enum ThumbnailError: LocalizedError {
    case imageLoadFailed
    case filterCreationFailed
    case scalingFailed
    case renderingFailed
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "Failed to load source image"
        case .filterCreationFailed:
            return "Failed to create Core Image filter"
        case .scalingFailed:
            return "Failed to scale image"
        case .renderingFailed:
            return "Failed to render thumbnail"
        case .generationFailed:
            return "Thumbnail generation failed"
        }
    }
}

// MARK: - Array Extension for Batching
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}