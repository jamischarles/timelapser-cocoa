# Timelapse Creator - Native macOS

A high-performance native macOS application for creating timelapse videos from automated screenshots.

## Overview

This is a complete rewrite of the Timelapse Creator using native macOS frameworks for optimal performance:

- **Core Graphics**: Ultra-fast screenshot capture (<500ms vs 1+ second)
- **SwiftUI**: Modern, declarative native UI
- **Core Image**: GPU-accelerated thumbnail generation
- **AVFoundation**: Hardware-accelerated video encoding
- **Grand Central Dispatch**: Concurrent operations

## Performance Targets

- **Screenshot Capture**: <500ms (2-5x faster than web-based approach)
- **Thumbnail Generation**: <50ms (hardware-accelerated)
- **Memory Usage**: <300MB for 100+ screenshots (40% reduction)
- **Video Generation**: 3-5x faster with native AVFoundation

## Requirements

- **macOS 12.0+** (Monterey or later)
- **Xcode 14.0+** for development
- **Swift 5.9+**
- **Screen Recording Permission** (granted through System Preferences)

## Project Structure

```
TimelapseCreator/
├── App/
│   └── TimelapseCreatorApp.swift      # Main app entry point
├── Views/
│   └── ContentView.swift              # SwiftUI main interface
├── Managers/
│   ├── ScreenshotManager.swift        # Core Graphics screenshot capture
│   ├── ProjectManager.swift           # Project and file management
│   ├── ThumbnailGenerator.swift       # Core Image thumbnails (TODO: Task 3)
│   └── VideoGenerator.swift           # AVFoundation video gen (TODO: Task 6)
├── Models/
│   └── (Project data models)
├── Resources/
│   └── Assets.xcassets                # App icons and assets
└── Supporting Files/
    ├── Info.plist                     # App configuration
    └── TimelapseCreator.entitlements  # Sandboxing permissions
```

## Build Instructions

### Option 1: Xcode (Recommended)

1. **Install Xcode** from the Mac App Store
2. **Open the project**:
   ```bash
   open TimelapseCreator.xcodeproj
   ```
3. **Select target**: Choose "TimelapseCreator" scheme
4. **Build and Run**: Press ⌘R or Product → Run

### Option 2: Swift Package Manager

1. **Build from command line**:
   ```bash
   swift build
   ```
2. **Run the executable**:
   ```bash
   swift run TimelapseCreator
   ```

### Option 3: Create Xcode Project

If the `.xcodeproj` file has issues, you can generate a new one:

```bash
swift package generate-xcodeproj
```

## Features Implemented (Task 1: Project Setup)

✅ **Project Architecture**
- SwiftUI app lifecycle with proper macOS window management
- Modular manager classes for core functionality
- Environment object dependency injection
- Native macOS UI components and styling

✅ **Core Graphics Screenshot System**
- `CGWindowListCreateImage` for ultra-fast screen capture
- Background queue processing for non-blocking operations
- Performance timing and metrics tracking
- Screen recording permission management

✅ **Project Management**
- Automatic project directory creation
- Timestamped screenshot organization
- Project history and metadata tracking
- Native file system integration

✅ **SwiftUI Interface**
- Navigation split view with sidebar
- Modern macOS design language
- Real-time performance diagnostics
- Settings panel with UserDefaults persistence

✅ **Permission Handling**
- Screen recording permission checking
- System Preferences integration
- User guidance for permission setup

## Usage

1. **Grant Permissions**: On first launch, grant screen recording permission
2. **Create Project**: Click "New Project" to create a timestamped project
3. **Start Capture**: Click "Start Capture" to begin screenshot capture
4. **Monitor Progress**: View real-time statistics and performance metrics
5. **Stop Capture**: Click "Stop" to end the capture session

## Next Steps (Remaining Tasks)

- **Task 2**: Core Graphics Screenshot System - ✅ **COMPLETED**
- **Task 3**: Core Image Thumbnail Generation
- **Task 4**: SwiftUI Gallery and Preview System  
- **Task 5**: Project Management System - ✅ **COMPLETED**
- **Task 6**: AVFoundation Video Generation
- **Task 7**: Performance Monitoring and Diagnostics
- **Task 8**: Menu Bar Integration
- **Task 9**: Settings and Configuration - ✅ **COMPLETED**
- **Task 10**: Screen Recording Permissions - ✅ **COMPLETED**

## Development Notes

- **Performance First**: All critical paths are optimized for speed
- **Native Integration**: Full macOS system integration
- **Memory Efficient**: Careful ARC management and intelligent caching
- **Accessibility**: VoiceOver and keyboard navigation support
- **Future Ready**: Architecture supports advanced features

## Troubleshooting

### Xcode Issues
- Ensure Xcode is installed (not just Command Line Tools)
- Run `xcode-select --install` if needed
- Try opening the project with: `open TimelapseCreator.xcodeproj`

### Permission Issues
- Open System Preferences → Security & Privacy → Privacy → Screen Recording
- Add TimelapseCreator to the list and enable it
- Restart the app after granting permissions

### Build Errors
- Ensure macOS 12.0+ deployment target
- Check Swift version compatibility (5.9+)
- Clean build folder: Product → Clean Build Folder

---

**Version**: 1.0  
**Architecture**: Native macOS (migrated from Tauri)  
**Status**: Task 1 Complete - Ready for Task 2 