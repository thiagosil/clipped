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

Clipped is a native macOS SwiftUI app for reading markdown articles saved from Obsidian. Users can select any folder via `Cmd+O` or the folder button (defaults to `~/Documents/ObsidianPKM/Clippings`).

### File Structure

```
Clipped/
├── Models/
│   ├── Article.swift           # Article data model
│   ├── ReadingProgress.swift   # Progress tracking model
│   └── ReadingSettings.swift   # Typography settings model
├── Services/
│   ├── ArticleService.swift    # Markdown parsing actor
│   ├── FolderSettingsStore.swift  # Folder path persistence
│   └── ReadingProgressStore.swift # Progress persistence
├── Views/
│   ├── ContentView.swift       # Main split view layout
│   ├── KeyboardShortcutsView.swift # Shortcuts help modal
│   ├── LibraryView.swift       # Sidebar with smart sections
│   ├── ReadingSettingsView.swift   # Typography popover
│   └── ReadingView.swift       # Article content renderer
├── AppState.swift              # Central state management
├── ClippedApp.swift            # App entry point
└── Theme.swift                 # Bear-inspired colors
```

### Key Components

**AppState** (`AppState.swift`) - Central @MainActor ObservableObject managing:
- Article list and selection state
- Search, filtering (by tags), and sorting (date/title/progress)
- Smart sections: Continue Reading, Quick Wins, The Stack
- Sidebar visibility toggle (`Cmd+B`)
- Keyboard shortcuts modal state
- Folder selection via FolderSettingsStore

**ArticleService** (`Services/ArticleService.swift`) - Actor that handles:
- Loading markdown files from user-selected folder
- Parsing YAML frontmatter (author, source, published, tags)
- Extracting title from H1 heading or filename
- Detecting Obsidian-style hashtags (#tag) in content
- Error handling for missing/invalid folders

**FolderSettingsStore** (`Services/FolderSettingsStore.swift`) - Persists user's selected folder path to UserDefaults.

**ReadingProgressStore** (`Services/ReadingProgressStore.swift`) - Persists reading progress (percentage, scroll position) to UserDefaults.

**Theme** (`Theme.swift`) - Bear-inspired color constants for dark sidebar and light content area.

### View Hierarchy

```
ClippedApp
└── ContentView (split view with animated sidebar)
    ├── LibraryView (sidebar)
    │   ├── Header (folder, filter, sort, refresh, random picker)
    │   ├── Active Filters (tag chips)
    │   ├── Smart Sections (Continue Reading / Quick Wins / The Stack)
    │   │   └── ArticleRow (progress indicator, metadata)
    │   └── Search Field (bottom, click-to-focus)
    ├── ResizeHandle (with hover feedback)
    └── ReadingView (main content)
        ├── Article Header (title, author, domain, time, tags)
        ├── MarkdownContentView (headers, paragraphs, code, images, etc.)
        ├── Toolbar (settings, open in browser)
        ├── Progress Bar (visual track with percentage)
        ├── Completion Overlay (checkmark at 100%)
        └── KeyboardShortcutsView (modal via ?)
```

### Data Model

**Article** - Immutable article data from markdown file:
- Parsed frontmatter: author, sourceURL, publishedDate, tags
- Computed: estimatedReadingTime (225 wpm), sourceDomain
- Mutable via AppState: readingProgress, scrollPosition

### State Flow

1. App loads → `AppState.loadArticles()` calls ArticleService
2. ArticleService parses all .md files from selected folder
3. AppState merges with persisted progress from ReadingProgressStore
4. Articles organized into smart sections (Continue Reading, Quick Wins, The Stack)
5. User selects article → `appState.selectedArticle` updates
6. ReadingView tracks scroll → saves progress via `appState.saveProgress()`

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Escape` / `Cmd+[` | Return to library |
| `Space` / `Shift+Space` | Scroll page down/up |
| `j` / `k` or `↓` / `↑` | Scroll line |
| `g g` | Go to top |
| `G` | Go to bottom |
| `n` | Next unread article |
| `Cmd+B` | Toggle sidebar |
| `Cmd+O` | Select folder |
| `Cmd+R` | Refresh articles |
| `?` | Show shortcuts help |

## Current Limitations

- Code blocks show language label but lack syntax highlighting colors
- Loading states during article refresh could be improved
