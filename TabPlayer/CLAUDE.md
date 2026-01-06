# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TabPlayer is a macOS application built with SwiftUI that helps musicians practice by displaying PDF tablatures alongside synchronized video lessons. It features a split-view interface with a searchable library sidebar and an advanced video player with A-B loop functionality for practicing specific sections.

## Build and Run

- **Open project**: `open TabPlayer.xcodeproj`
- **Build**: Cmd+B in Xcode or `xcodebuild -project TabPlayer.xcodeproj -scheme TabPlayer build`
- **Run**: Cmd+R in Xcode or `xcodebuild -project TabPlayer.xcodeproj -scheme TabPlayer run`

## Architecture

### Core Data Models (`models/Models.swift`)
- `Artiste`: Represents a musician/artist with a collection of songs
- `Song`: Contains title and optional URLs to PDF tablature and video files

### File System Structure
The app expects a specific folder hierarchy set via Settings:
```
Root Folder/
  └─ Artist Name/
      └─ Song Title/
          ├─ tablature.pdf
          └─ video.mp4
```

The `scanLibrary(rootPath:)` function in `ContentView.swift:148` recursively scans this structure to build the library.

### Main Views

**ContentView.swift**
- Main application interface using `NavigationSplitView`
- Left sidebar: searchable artist/song list with expandable sections
- Right detail pane: `HSplitView` containing PDF and video players side-by-side
- Search functionality filters both artist names and song titles
- Artists are sorted alphabetically with colored circle avatars based on name hash

**VideoPlayerView.swift**
- Complex video player with A-B loop functionality for practice
- `PlayerViewModel`: Manages AVPlayer state, loop points, and time observation
- Loop system uses two capture points (A and B) with manual fine-tuning via steppers
- `TimeEditor`: Custom control for editing timestamps with ±0.1s and ±1s adjustments
- `LoopProgressBar`: Visual representation of current position and loop region
- Custom speed control menu (0.25x to 2.0x playback)

**PDFKitView.swift**
- Simple PDFKit wrapper for displaying tablature PDFs with auto-scaling

**SettingView.swift**
- Settings window for configuring root folder path via `@AppStorage`
- Provides folder picker dialog for selecting the music library location

### Key Implementation Details

**Video Loop System**
- Uses `AVPlayer.addPeriodicTimeObserver` with 33ms interval for precise loop detection
- Loop validation ensures loopStart < loopEnd via Combine publishers
- Seeking uses `CMTime` with zero tolerance for accurate positioning
- Loop state automatically updates when both points are validly set

**Time Format Parsing**
- Supports multiple input formats: "mm:ss.d", "mm:ss", or just seconds
- Display format: "MM:SS.d" (minutes:seconds.deciseconds)
- Edit format: simplified for user input (e.g., "45.3" or "1:23.5")

**Library Management**
- Uses `@AppStorage` to persist root folder path across app launches
- File discovery filters for PDF and video extensions (mp4, mov, m4v)
- Songs and artists are automatically sorted alphabetically

## Development Notes

- SwiftUI-based macOS application (no Catalyst/UIKit)
- Minimum target should support `NavigationSplitView` (macOS 13.0+)
- Uses Combine for reactive state management in video player
- AppStorage keys: `"rootFolderURL"` stores the library root path
