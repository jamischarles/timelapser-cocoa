# Architecture Document - Native macOS Timelapse Creator

## Overview
This document outlines the technical architecture for the native macOS implementation of the Timelapse Creator application. The architecture prioritizes **performance as critical** and leverages native macOS frameworks for optimal speed and efficiency.

## Architecture Migration: Tauri → Native macOS

### Migration Rationale
- **Performance Critical**: Direct access to macOS APIs eliminates web engine overhead
- **Native Integration**: True macOS look, feel, and system integration
- **Memory Efficiency**: 30-50% reduction in memory usage vs web-based approach
- **Hardware Acceleration**: Direct access to Metal, Core Image, and VideoToolbox
- **Maintainability**: Simpler codebase with fewer dependencies

### Expected Performance Gains
- **Screenshot Capture**: 2-5x faster (500ms vs 1+ second)
- **Thumbnail Generation**: 2x faster (50ms vs 100ms)
- **Memory Usage**: 40% reduction (300MB vs 500MB for 100 screenshots)
- **Video Generation**: 3-5x faster with hardware-accelerated encoding

## Core Architecture

### Technology Stack

#### Primary Frameworks
- **Swift 5.5+**: Primary language with async/await and actors
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming and state management
- **Core Graphics**: High-performance screenshot capture
- **Core Image**: GPU-accelerated image processing
- **AVFoundation**: Native video generation
- **Grand Central Dispatch**: Concurrent operations

#### System Integration
- **AppKit**: Performance-critical UI components
- **Core Data**: Optional for complex project metadata
- **UserDefaults**: Settings and preferences
- **NSFileManager**: Async file operations
- **Metal Performance Shaders**: Advanced image processing

### Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI App                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Main Window   │  │  Gallery View   │  │ Settings View│ │
│  │                 │  │                 │  │              │ │
│  │ • Capture Controls│ │ • LazyVGrid     │  │ • UserDefaults│ │
│  │ • Status Display │  │ • AsyncImage    │  │ • Preferences │ │
│  │ • Performance    │  │ • Smooth Scroll │  │ • Permissions │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    Business Logic Layer                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Screenshot      │  │ Project         │  │ Video        │ │
│  │ Manager         │  │ Manager         │  │ Generator    │ │
│  │                 │  │                 │  │              │ │
│  │ • Core Graphics │  │ • File System   │  │ • AVFoundation│ │
│  │ • Timing        │  │ • Metadata      │  │ • Hardware    │ │
│  │ • Permissions   │  │ • Cache         │  │   Encoding   │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    System Integration                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Core Graphics   │  │ Core Image      │  │ AVFoundation │ │
│  │                 │  │                 │  │              │ │
│  │ • Screen Capture│  │ • Thumbnails    │  │ • Video Gen  │ │
│  │ • Multi-Monitor │  │ • GPU Accel     │  │ • Hardware   │ │
│  │ • Window List   │  │ • Filters       │  │ • Codecs     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Screenshot Manager
**Primary Responsibility**: High-performance screen capture

**Implementation**:
```swift
@MainActor
class ScreenshotManager: ObservableObject {
    private let captureQueue = DispatchQueue(label: "screenshot.capture", qos: .userInitiated)
    private let fileQueue = DispatchQueue(label: "screenshot.file", qos: .utility)
    
    func captureScreen() async throws -> CGImage {
        return try await withCheckedThrowingContinuation { continuation in
            captureQueue.async {
                // CGWindowListCreateImage implementation
                let image = CGWindowListCreateImage(.null, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
                continuation.resume(returning: image)
            }
        }
    }
}
```

**Key Features**:
- **CGWindowListCreateImage**: Ultra-fast native screen capture
- **Multi-Monitor Support**: Core Graphics display enumeration
- **Capture Areas**: Full screen, window selection, custom regions
- **Concurrent Operations**: GCD for non-blocking capture
- **Permission Handling**: CGPreflightScreenCaptureAccess

**Performance Targets**:
- <500ms capture time
- Concurrent capture and file I/O
- Memory-efficient handling of large images

### 2. Thumbnail Generator
**Primary Responsibility**: GPU-accelerated thumbnail creation

**Implementation**:
```swift
class ThumbnailGenerator {
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    
    func generateThumbnail(from image: CGImage, size: CGSize) async -> CGImage? {
        return await withCheckedContinuation { continuation in
            let ciImage = CIImage(cgImage: image)
            let filter = CIFilter.lanczosScaleTransform()
            filter.inputImage = ciImage
            filter.scale = Float(size.width / ciImage.extent.width)
            
            if let output = filter.outputImage,
               let cgImage = context.createCGImage(output, from: output.extent) {
                continuation.resume(returning: cgImage)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
```

**Key Features**:
- **Core Image Filters**: GPU-accelerated resizing
- **Batch Processing**: Multiple thumbnails concurrently
- **Memory Management**: NSCache for intelligent caching
- **Quality Optimization**: Lanczos scaling for best quality

**Performance Targets**:
- <50ms per thumbnail
- Hardware acceleration via Metal
- 90%+ file size reduction

### 3. Project Manager
**Primary Responsibility**: File system and metadata management

**Implementation**:
```swift
@MainActor
class ProjectManager: ObservableObject {
    @Published var currentProject: Project?
    @Published var projects: [Project] = []
    
    private let fileManager = FileManager.default
    private let documentsURL = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask).first!
    
    func createProject(name: String) async throws -> Project {
        let projectURL = documentsURL.appendingPathComponent("TimelapseCaptureProjects/\(name)")
        try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
        
        let project = Project(name: name, url: projectURL, createdAt: Date())
        projects.append(project)
        return project
    }
}
```

**Key Features**:
- **Structured Storage**: Organized project directories
- **Metadata Tracking**: Project statistics and history
- **File Monitoring**: FSEvents for real-time updates
- **Search and Filter**: Fast project discovery

### 4. Video Generator
**Primary Responsibility**: Native video creation using AVFoundation

**Implementation**:
```swift
class VideoGenerator {
    func generateVideo(from images: [URL], settings: VideoSettings) async throws -> URL {
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: settings.resolution.width,
            AVVideoHeightKey: settings.resolution.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: settings.bitRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: nil)
        
        writer.add(videoInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Process images with hardware acceleration
        for (index, imageURL) in images.enumerated() {
            let presentationTime = CMTime(value: Int64(index), timescale: Int32(settings.fps))
            // Convert CGImage to CVPixelBuffer and append
        }
        
        await writer.finishWriting()
        return outputURL
    }
}
```

**Key Features**:
- **AVAssetWriter**: Direct MP4 creation
- **VideoToolbox**: Hardware-accelerated encoding
- **Streaming Processing**: No full image buffer required
- **Progress Reporting**: Real-time generation progress
- **Multiple Formats**: H.264, HEVC support

**Performance Targets**:
- 3-5x faster than FFmpeg
- Hardware acceleration
- Minimal memory footprint

## Data Flow Architecture

### Screenshot Capture Flow
```
User Trigger → Screenshot Manager → Core Graphics → File System → Thumbnail Generator → UI Update
     ↓              ↓                    ↓              ↓              ↓               ↓
   Button        CGWindowList       CGImage        NSFileManager   Core Image     SwiftUI
   Press         CreateImage        Creation       Async Write     GPU Process    Reactive
                                                                                 Update
```

### Gallery Loading Flow
```
View Appears → Project Manager → File Discovery → Thumbnail Cache → Lazy Loading → UI Display
     ↓              ↓                ↓              ↓               ↓              ↓
  SwiftUI        NSFileManager    Directory       NSCache        AsyncImage     LazyVGrid
  onAppear       Enumeration      Scanning        Hit/Miss       Background     60fps
                                                                Load          Scrolling
```

### Video Generation Flow
```
User Request → Image Collection → AVAssetWriter → Hardware Encode → Progress Update → Completion
     ↓              ↓                  ↓               ↓               ↓              ↓
   Generate       File System       Video Setup    VideoToolbox    Combine       Sharing
   Button         Enumeration       Configuration   H.264/HEVC     Publisher     Extension
```

## Performance Optimizations

### Memory Management
- **ARC**: Automatic Reference Counting with cycle detection
- **NSCache**: Intelligent thumbnail caching with memory pressure handling
- **Lazy Loading**: On-demand image loading in gallery
- **Background Processing**: CPU-intensive tasks on background queues

### Concurrency Architecture
```swift
// Screenshot capture on dedicated queue
private let screenshotQueue = DispatchQueue(label: "screenshot", qos: .userInitiated)

// File I/O on utility queue
private let fileQueue = DispatchQueue(label: "file", qos: .utility)

// Thumbnail generation on concurrent queue
private let thumbnailQueue = DispatchQueue(label: "thumbnail", qos: .default, attributes: .concurrent)

// UI updates always on main actor
@MainActor
class AppViewModel: ObservableObject { }
```

### Hardware Acceleration
- **Metal**: GPU-accelerated image processing via Core Image
- **VideoToolbox**: Hardware video encoding
- **Core Animation**: Layer-backed views for smooth UI
- **CADisplayLink**: Precise frame rate monitoring

## Security and Permissions

### Screen Recording Permissions
```swift
func checkScreenRecordingPermission() -> Bool {
    return CGPreflightScreenCaptureAccess()
}

func requestScreenRecordingPermission() {
    // Trigger system permission dialog
    CGRequestScreenCaptureAccess()
}
```

### File System Access
- **Sandboxing**: Proper entitlements for file access
- **User Directories**: Documents folder for project storage
- **Temporary Files**: NSTemporaryDirectory for processing

## Testing Strategy

### Unit Testing
- **XCTest**: Core business logic testing
- **Mock Objects**: File system and Core Graphics mocking
- **Performance Testing**: XCTMetric for timing validation

### Integration Testing
- **UI Testing**: XCUITest for end-to-end workflows
- **Instruments**: Memory leak and performance profiling
- **Accessibility Testing**: VoiceOver compatibility

### Performance Benchmarking
```swift
func testScreenshotCapturePerformance() {
    measure {
        // Measure screenshot capture time
        let image = CGWindowListCreateImage(.null, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
    }
    // Target: <500ms
}
```

## Deployment and Distribution

### Build Configuration
- **Xcode Project**: Native Swift package structure
- **Deployment Target**: macOS 12.0+
- **Architecture**: Universal Binary (Intel + Apple Silicon)
- **Code Signing**: Developer ID for distribution

### Distribution Options
- **Mac App Store**: Sandboxed version with limitations
- **Direct Distribution**: Full feature set with enhanced permissions
- **TestFlight**: Beta testing and feedback collection

## Monitoring and Analytics

### Performance Monitoring
- **os_signpost**: System-level performance tracking
- **Instruments Integration**: Real-time profiling
- **Custom Metrics**: Screenshot timing, memory usage, UI responsiveness

### Error Handling
```swift
enum ScreenshotError: LocalizedError {
    case permissionDenied
    case captureFailure
    case fileSystemError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission required"
        case .captureFailure:
            return "Failed to capture screenshot"
        case .fileSystemError:
            return "Unable to save screenshot"
        }
    }
}
```

## Future Architecture Considerations

### Scalability
- **Multi-Window Support**: Document-based architecture
- **Plugin System**: NSBundle-based extensions
- **Cloud Integration**: CloudKit for project sync
- **Machine Learning**: Core ML for intelligent capture

### Performance Enhancements
- **Metal Compute**: Custom GPU kernels for image processing
- **Background App Refresh**: Scheduled captures when app is backgrounded
- **Streaming**: Real-time video generation during capture

## FFmpeg Integration (Optional)

While the primary implementation uses native AVFoundation for video generation, FFmpeg can be optionally integrated for:

- **Advanced Codec Support**: Additional video formats beyond H.264/HEVC
- **Complex Processing**: Advanced video filters and effects
- **Fallback Option**: Alternative encoding if hardware acceleration unavailable
- **User Preference**: Allow users to choose encoding method

### FFmpeg Integration Approach
- **Command-line Binary**: Bundle static FFmpeg binary for macOS
- **Process Management**: Swift Process API for execution
- **Progress Parsing**: Parse FFmpeg output for progress updates
- **Error Handling**: Robust error checking and fallback

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Target Platform:** macOS 12.0+  
**Architecture Status:** Ready for Implementation 