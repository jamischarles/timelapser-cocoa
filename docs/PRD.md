# Product Requirements Document (PRD)
## Timelapse Creator Application

### Overview
Timelapse Creator is a **native macOS application** that captures periodic screenshots and generates timelapse videos. The app provides real-time preview capabilities and efficient thumbnail management for optimal performance. **Performance is critical** - the application must be highly optimized for speed and efficiency.

### Target Users
- Content creators who need to document work processes
- Developers recording coding sessions
- Designers showcasing creative workflows
- Anyone needing automated screen recording capabilities

### Core Features

#### 1. Screenshot Capture System
**Requirements:**
- Capture full-resolution screenshots at user-defined intervals (1-30 seconds)
- Save screenshots to disk in organized project directories
- Support concurrent capture and file I/O operations
- Provide real-time capture status and count feedback
- Generate unique timestamps for each screenshot

**Technical Specifications:**
- File format: PNG
- Storage location: `~/TimelapseCaptureProjects/ProjectName_Timestamp/`
- Naming convention: `screenshot_YYYYMMDD_HHMMSS.png`
- Asynchronous file operations to maintain UI responsiveness

#### 2. Thumbnail Generation System
**Requirements:**
- Automatically generate thumbnails for all captured screenshots
- Save thumbnails to disk alongside full-resolution images
- Optimize thumbnail size for fast gallery loading
- Maintain aspect ratio during thumbnail creation

**Technical Specifications:**
- Thumbnail dimensions: 200x150 pixels
- File naming: `screenshot_YYYYMMDD_HHMMSS_thumb.png`
- Compression: Optimized for size while maintaining visual quality
- Target size: ~24KB per thumbnail (vs ~12MB full image)

#### 3. Gallery and Preview System
**Requirements:**
- Display thumbnails in a responsive grid layout
- Load thumbnails on-demand for gallery view
- Load full-resolution images only for preview
- Support click-to-preview functionality
- Show capture count badges on thumbnails

**Performance Requirements:**
- Gallery should load thumbnails within 100ms per image
- Preview should load full images within 500ms
- UI should remain responsive during image loading
- Support 100+ screenshots without performance degradation

#### 4. Project Management
**Requirements:**
- Create timestamped project directories
- Support multiple concurrent projects
- Maintain project history and metadata
- Track screenshot count and capture duration

#### 5. User Interface
**Requirements:**
- Real-time performance diagnostics display
- Capture status indicators
- Project configuration options
- Responsive design supporting various screen sizes

**UI Components:**
- Performance diagnostics panel showing:
  - UI FPS
  - Screenshot FPS  
  - Last decode time
- Capture control buttons (Start/Stop)
- Project settings (name, interval)
- Screenshot gallery with thumbnails
- Large preview pane
- Project history view

### Technical Architecture

#### Native macOS Implementation
**Core Technologies:**
- **Cocoa/AppKit**: Primary application framework for native macOS UI
- **Core Graphics**: High-performance screenshot capture using CGWindowListCreateImage
- **Core Image**: Efficient image processing and thumbnail generation
- **AVFoundation**: Video generation from screenshot sequences
- **Grand Central Dispatch (GCD)**: Concurrent operations and background processing
- **Swift/Objective-C**: Primary development languages for optimal performance

#### Backend (Native macOS)
- **Screenshot capture**: Core Graphics CGWindowListCreateImage for ultra-fast screen capture
- **Image processing**: Core Image CIFilter for hardware-accelerated thumbnail generation
- **File I/O**: NSFileManager with async operations using GCD
- **State management**: Thread-safe property wrappers and actors (Swift 5.5+)
- **Video generation**: AVAssetWriter for direct MP4/MOV creation (optional FFmpeg integration)

#### Frontend (Native macOS)
- **UI Framework**: SwiftUI for modern, declarative interface OR AppKit for maximum performance control
- **State management**: Combine framework for reactive programming
- **Image loading**: NSImage with efficient caching and lazy loading
- **Performance monitoring**: Real-time FPS and decode time tracking using CADisplayLink
- **UI components**: Native macOS controls with custom performance-optimized views

#### Performance Optimizations
- **Hardware Acceleration**: Leverage Metal Performance Shaders for image processing
- **Memory Management**: ARC with careful attention to retain cycles and memory peaks
- **Background Processing**: All I/O operations on background queues
- **Efficient Rendering**: Core Animation and layer-backed views for smooth UI
- **Caching Strategy**: Intelligent NSCache usage for thumbnails and metadata

### Performance Requirements

#### Screenshot Capture
- Target capture time: <500ms per screenshot (improved from 1 second)
- File save time: <100ms per screenshot (improved from 200ms)
- Thumbnail generation: <50ms per thumbnail (improved from 100ms)

#### Memory Usage
- Thumbnail cache: Intelligent loading/unloading with NSCache
- Full image cache: Limited to currently viewed images
- Maximum memory usage: <300MB for 100 screenshots (improved from 500MB)

#### File System
- Disk space efficiency: Thumbnails reduce gallery loading by 500x
- File organization: Structured directory hierarchy
- Concurrent I/O: Non-blocking file operations using GCD

#### Video Generation
- **Native AVFoundation**: Primary method for best performance and integration
- **FFmpeg (Optional)**: Available for advanced codec support if needed
- **Hardware Encoding**: Utilize VideoToolbox for H.264/HEVC acceleration
- **Streaming Generation**: Process videos without loading all images into memory

### Quality Assurance

#### Testing Requirements
- Functional testing for all capture scenarios
- Performance testing with extended capture sessions
- UI responsiveness testing during heavy operations
- File system integrity testing
- macOS version compatibility testing (macOS 12+ target)
- Memory leak detection using Instruments

#### Success Metrics
- Screenshot capture reliability: >99.9%
- UI responsiveness: No blocking operations >50ms (improved from 100ms)
- File system performance: No I/O bottlenecks
- User experience: Smooth gallery navigation at 60fps
- Memory efficiency: <200MB baseline usage (improved target)

### Development Guidelines

#### Code Quality
- Write minimal, focused code
- No sweeping architectural changes
- Maintain existing functionality
- Create modular, testable components
- Follow dev/prod parity principles
- **Native macOS best practices**: Follow Apple's Human Interface Guidelines
- **Performance-first mindset**: Profile and optimize all critical paths

#### Task Management
- Track all work in tasks.md
- Record task status, duration, prompt count, and costs
- Complete one task at a time
- Test thoroughly before moving to next task

### Future Considerations

#### Potential Enhancements
- **Native video generation**: Full AVFoundation pipeline
- **iCloud integration**: Seamless project sync across devices
- **Advanced image filtering**: Core Image filter chains
- **Automated timelapse settings**: ML-based optimization
- **Export format options**: Multiple video codecs and formats
- **Menu bar app**: Lightweight always-available interface

#### Scalability
- Support for multiple monitors using Core Graphics display APIs
- Batch processing capabilities with NSOperation queues
- **Native sharing**: Integration with macOS sharing extensions
- **Plugin system**: Native extension points using NSBundle

### Technical Debt and Maintenance

#### Known Limitations
- macOS-only implementation (by design)
- Requires macOS 12+ for optimal performance
- Screen recording permissions required

#### Maintenance Requirements
- Regular performance monitoring using Instruments
- File system cleanup utilities
- macOS version compatibility testing
- Documentation updates

#### Migration from Tauri
- **Architecture Change**: Complete rewrite using native macOS frameworks
- **Performance Gains**: Expected 2-5x improvement in screenshot capture speed
- **Memory Efficiency**: 30-50% reduction in memory usage
- **User Experience**: Native macOS look, feel, and integration
- **Maintenance**: Simpler codebase with fewer dependencies

---

**Document Version:** 2.0  
**Last Updated:** January 2025  
**Status:** Architecture Migration - Tauri → Native macOS
**Performance Target**: Critical - optimize for speed and efficiency 