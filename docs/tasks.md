# Tasks Tracker - Native macOS Implementation

## Task Status Legend
- **Not Started** - Task identified but not begun
- **In Progress** - Currently being worked on
- **Completed** - Finished and tested
- **Blocked** - Waiting on dependencies
- **Archived** - From previous Tauri implementation

---

## Architecture Migration - Tauri → Native macOS

### Migration Overview
**Status:** In Progress 🚧  
**Target:** Complete rewrite using native macOS frameworks for optimal performance  
**Performance Goal:** 2-5x improvement in screenshot capture speed  
**Memory Target:** 30-50% reduction in memory usage  

### Why Native macOS?
- **Performance Critical**: Direct access to macOS APIs for fastest possible screenshot capture
- **Native Integration**: True macOS look, feel, and system integration
- **Reduced Overhead**: Eliminate web engine and JavaScript bridge overhead
- **Hardware Acceleration**: Direct access to Metal, Core Image, and VideoToolbox
- **Memory Efficiency**: No web engine memory footprint

---

## New Native macOS Tasks

### Task 1: Project Setup and Core Architecture
- **Status:** Not Started
- **Priority:** Critical
- **Estimated Duration:** 2-3 hours
- **Description:** Set up Xcode project with Swift/SwiftUI architecture

**Components to Implement:**
- Xcode project setup with SwiftUI app lifecycle
- Core project structure and file organization
- Basic app window and navigation structure
- macOS deployment target (macOS 12+)
- Bundle identifier and app metadata
- Git repository initialization

**Technical Requirements:**
- SwiftUI for modern UI (with AppKit fallback for performance-critical sections)
- Combine framework for reactive state management
- Swift Package Manager for dependencies (minimal external dependencies)
- Core Data or JSON for project metadata storage

### Task 2: Core Graphics Screenshot System
- **Status:** Not Started
- **Priority:** Critical
- **Estimated Duration:** 3-4 hours
- **Description:** Implement high-performance screenshot capture using Core Graphics

**Components to Implement:**
- CGWindowListCreateImage for screen capture
- Display selection (multiple monitor support)
- Capture area selection (full screen, window, region)
- Screenshot timing and interval management
- File I/O with async operations using GCD
- Error handling and permission checking

**Performance Targets:**
- <500ms capture time (vs 1+ second in Tauri)
- Concurrent capture and file operations
- Memory-efficient large image handling

### Task 3: Core Image Thumbnail Generation
- **Status:** Not Started
- **Priority:** High
- **Estimated Duration:** 2 hours
- **Description:** Hardware-accelerated thumbnail generation using Core Image

**Components to Implement:**
- CIFilter-based image resizing for GPU acceleration
- Batch thumbnail generation for multiple images
- Efficient JPEG/PNG compression for optimal file sizes
- Background processing with progress reporting
- NSCache integration for intelligent memory management

**Performance Targets:**
- <50ms per thumbnail (vs 100ms in Tauri)
- Hardware-accelerated processing
- Memory-efficient batch operations

### Task 4: SwiftUI Gallery and Preview System
- **Status:** Not Started
- **Priority:** High
- **Estimated Duration:** 4-5 hours
- **Description:** Native SwiftUI gallery with lazy loading and smooth animations

**Components to Implement:**
- LazyVGrid for efficient thumbnail display
- AsyncImage with custom caching for thumbnails
- Smooth zoom/preview animations
- Pull-to-refresh and infinite scrolling
- Selection and multi-selection support
- Keyboard navigation and accessibility

**Performance Targets:**
- 60fps scrolling performance
- <100ms thumbnail load times
- Smooth transitions and animations

### Task 5: Project Management System
- **Status:** Not Started
- **Priority:** Medium
- **Estimated Duration:** 3 hours
- **Description:** Native project management with Core Data or JSON storage

**Components to Implement:**
- Project creation and metadata tracking
- File system organization and monitoring
- Project history and statistics
- Import/export functionality
- Search and filtering capabilities

### Task 6: AVFoundation Video Generation
- **Status:** Not Started
- **Priority:** High
- **Estimated Duration:** 4-6 hours
- **Description:** Native video generation using AVFoundation for optimal performance

**Components to Implement:**
- AVAssetWriter for direct MP4 creation
- VideoToolbox hardware encoding (H.264/HEVC)
- Progress reporting and cancellation support
- Custom video settings (FPS, quality, resolution)
- Background processing with minimal memory usage
- Export sharing integration

**Performance Targets:**
- 3-5x faster than FFmpeg processing
- Hardware-accelerated encoding
- Streaming processing (no full image buffer)

**Optional FFmpeg Integration:**
- Fallback for advanced codec support
- Command-line integration if needed
- User preference for encoding method

### Task 7: Performance Monitoring and Diagnostics
- **Status:** Not Started
- **Priority:** Medium
- **Estimated Duration:** 2 hours
- **Description:** Real-time performance monitoring using native macOS tools

**Components to Implement:**
- CADisplayLink for accurate FPS measurement
- Memory usage tracking with os_signpost
- Capture timing and file I/O performance metrics
- SwiftUI performance overlay
- Export performance reports

### Task 8: Menu Bar Integration and System Integration
- **Status:** Not Started
- **Priority:** Low
- **Estimated Duration:** 2-3 hours
- **Description:** Native macOS system integration and menu bar app

**Components to Implement:**
- NSStatusItem menu bar presence
- Global hotkeys for capture control
- System notification integration
- macOS sharing extensions
- Dock tile progress indication

### Task 9: Settings and Configuration
- **Status:** Not Started
- **Priority:** Medium
- **Estimated Duration:** 2 hours
- **Description:** Native settings panel with UserDefaults persistence

**Components to Implement:**
- SwiftUI Settings scene
- UserDefaults property wrappers
- Capture interval and quality settings
- File organization preferences
- Accessibility and performance options

### Task 10: Screen Recording Permissions and Security
- **Status:** Not Started
- **Priority:** Critical
- **Estimated Duration:** 1-2 hours
- **Description:** Proper macOS screen recording permission handling

**Components to Implement:**
- CGPreflightScreenCaptureAccess permission checking
- User guidance for granting permissions
- Graceful degradation when permissions denied
- Privacy-focused permission requests

---

## Archived Tasks (Previous Tauri Implementation)

### ✅ Previously Completed in Tauri (Archived)
The following tasks were completed in the previous Tauri implementation and serve as reference for the native macOS version:

1. **Disk-Based Screenshot and Thumbnail System** - Architecture reference
2. **Thumbnail Display in Gallery** - UI/UX patterns to replicate
3. **Backend Compilation Error Fixes** - Not applicable to Swift
4. **File-Based Image Loading Migration** - Native NSImage implementation
5. **Video Generation from Screenshots** - AVFoundation implementation target
6. **Project Management Features** - Core Data/JSON implementation target
7. **Memory Usage Optimization** - NSCache implementation target
8. **Inception Screenshot Mode** - System integration reference
9. **macOS Screen Recording Permissions** - Direct implementation needed
10. **App Stability and Performance** - Native performance targets
11. **FFmpeg Screenshots** - Optional integration, AVFoundation preferred
12. **Capture Area Selection** - Core Graphics implementation target

---

## Development Metrics

### Current Sprint Summary (Native macOS Implementation)
- **Tasks Completed:** 0
- **Total Development Time:** 0 hours
- **Total Prompts Used:** 0
- **Estimated Total Cost:** $0
- **Architecture:** Migration to Native macOS

### Performance Benchmarks (Targets)
- **Screenshot Capture Time:** <500ms (vs 1+ second in Tauri)
- **Thumbnail Generation:** <50ms per thumbnail (vs 100ms in Tauri)
- **Memory Usage:** <300MB for 100 screenshots (vs 500MB in Tauri)
- **UI Responsiveness:** 60fps sustained performance
- **Video Generation:** 3-5x faster with AVFoundation

### Architecture Comparison

| Feature | Tauri Implementation | Native macOS Implementation |
|---------|---------------------|---------------------------|
| Screenshot Capture | FFmpeg + Plugin | Core Graphics CGWindowListCreateImage |
| Image Processing | Rust image crate | Core Image CIFilter (GPU-accelerated) |
| UI Framework | React/TypeScript | SwiftUI/AppKit |
| State Management | React hooks | Combine framework |
| File I/O | Tokio async | GCD with NSFileManager |
| Video Generation | FFmpeg binary | AVFoundation + VideoToolbox |
| Memory Management | Manual + GC | ARC with intelligent caching |
| System Integration | Limited | Full native macOS integration |

---

## Notes

### Development Principles for Native macOS
- ✅ Performance-first mindset - profile and optimize all critical paths
- ✅ Native macOS best practices - follow Apple's Human Interface Guidelines
- ✅ Minimal external dependencies - leverage native frameworks
- ✅ Hardware acceleration - use Metal, Core Image, VideoToolbox
- ✅ Memory efficiency - ARC with careful attention to retain cycles
- ✅ 60fps UI - smooth animations and responsive interface
- ✅ Accessibility - VoiceOver and keyboard navigation support

### Migration Strategy
1. **Phase 1**: Core screenshot capture with Core Graphics
2. **Phase 2**: SwiftUI gallery with thumbnail system
3. **Phase 3**: AVFoundation video generation
4. **Phase 4**: System integration and performance optimization
5. **Phase 5**: Advanced features and polish

### Success Criteria
- **Performance**: 2-5x improvement in all core operations
- **Memory**: 30-50% reduction in memory usage
- **User Experience**: Native macOS look, feel, and integration
- **Maintainability**: Simpler codebase with fewer dependencies

---

**Last Updated:** January 2025  
**Current Phase:** Project Setup (Task 1)  
**Next Milestone:** Core Graphics Screenshot System (Task 2)

**Migration Status:** 🚧 Ready to begin native macOS implementation 