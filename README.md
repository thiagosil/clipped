# Clipped

A native macOS app for reading markdown articles saved from Obsidian. Features a Bear-inspired design with a dark sidebar and light content area.

## Features

- Reads markdown files from your Obsidian Clippings folder
- Parses YAML frontmatter (author, source, published date, tags)
- Detects Obsidian-style hashtags (#tag) in content
- Estimated reading time (225 wpm)
- Reading progress tracking with scroll position persistence
- Search and filter by tags
- Customizable typography settings

## Requirements

- macOS 13.0+
- Xcode 15.0+

## Building

```bash
# Open in Xcode
open Clipped.xcodeproj

# Or build from command line
cd Clipped
xcodebuild -scheme Clipped -configuration Debug build

# Build for release
xcodebuild -scheme Clipped -configuration Release build
```

## Configuration

By default, Clipped reads markdown files from `~/Documents/ObsidianPKM/Clippings`. You can change this folder in the app's settings.

## Architecture

```
ClippedApp
└── ContentView (split view with resize handle)
    ├── LibraryView (sidebar - article list, search, tag filter)
    └── ReadingView (main content - markdown rendering)
        └── ReadingSettingsView (typography popover)
```

### Key Components

- **AppState** - Central state management for articles, selection, search, and filtering
- **ArticleService** - Loads and parses markdown files with frontmatter extraction
- **ReadingProgressStore** - Persists reading progress to UserDefaults
- **Theme** - Bear-inspired color constants

## License

MIT
