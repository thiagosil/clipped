# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the app from command line
cd Clipped
xcodebuild -scheme Clipped -configuration Debug build

# Build for release
xcodebuild -scheme Clipped -configuration Release build

# Open in Xcode
open Clipped.xcodeproj
```

## Architecture Overview

Clipped is a native macOS SwiftUI app for reading markdown articles saved from Obsidian. It reads from a hardcoded folder path (`/Users/thiago/Documents/ObsidianPKM/Clippings`).

### Key Components

**AppState** (`AppState.swift`) - Central @MainActor ObservableObject managing:
- Article list and selection state
- Search, filtering, and sorting
- Reading progress coordination between ArticleService and ReadingProgressStore

**ArticleService** (`Services/ArticleService.swift`) - Actor that handles:
- Loading markdown files from the Clippings folder
- Parsing YAML frontmatter (author, source, published, tags)
- Extracting title from H1 heading or filename
- Detecting Obsidian-style hashtags (#tag) in content

**ReadingProgressStore** (`Services/ReadingProgressStore.swift`) - Persists reading progress (percentage, scroll position) to UserDefaults.

**Theme** (`Theme.swift`) - Bear-inspired color constants for dark sidebar and light content area.

### View Hierarchy

```
ClippedApp
└── ContentView (split view with resize handle)
    ├── LibraryView (sidebar - article list, search, tag filter)
    └── ReadingView (main content - markdown rendering)
        └── ReadingSettingsView (typography popover)
```

### Data Model

**Article** - Immutable article data from markdown file:
- Parsed frontmatter: author, sourceURL, publishedDate, tags
- Computed: estimatedReadingTime (225 wpm), sourceDomain
- Mutable via AppState: readingProgress, scrollPosition

### State Flow

1. App loads → `AppState.loadArticles()` calls ArticleService
2. ArticleService parses all .md files, extracts frontmatter
3. AppState merges with persisted progress from ReadingProgressStore
4. User selects article → `appState.selectedArticle` updates
5. ReadingView tracks scroll → saves progress via `appState.saveProgress()`

## Current Limitations (see TODO.md)

- No keyboard navigation (Space/j/k/gg/G shortcuts)
- Basic markdown rendering (no syntax highlighting, images)
- Scroll position restoration needs testing
