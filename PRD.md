# Product Requirements Document: Markdown Reader for Mac

## Overview

A native macOS application for reading markdown articles saved from the web via Obsidian. The app provides a distraction-free reading experience with a clean library interface, inspired by Readwise Reader.

## Problem Statement

When saving articles from the web to Obsidian as markdown files, the reading experience within Obsidian is suboptimal for focused reading. Users need a dedicated reader that:
- Presents a clean library of saved articles
- Provides beautiful, distraction-free reading typography
- Tracks reading progress across articles

## Target User

Personal use for a single user who saves web articles to markdown via Obsidian and wants a focused reading experience.

## Technical Approach

- **Platform**: macOS (native app)
- **Framework**: SwiftUI
- **Data Source**: Local folder containing markdown files
- **File Format**: Markdown with YAML frontmatter

## Data Source

**Folder Location**: `/Users/thiago/Documents/ObsidianPKM/Clippings`

**File Format Example**:
```markdown
---
author:
  - "Author Name"
published:
source: "https://example.com/article"
---

Article content in markdown...
```

**Frontmatter Fields**:
- `author`: Article author (array or string)
- `published`: Publication date
- `source`: Original URL

---

## Core Features

### 1. Library View

The main screen showing all saved articles.

**Layout**:
- List of articles with:
  - Title (extracted from filename or first H1)
  - Author (from frontmatter)
  - Source domain (from frontmatter URL)
  - Estimated reading time (calculated from word count)
  - Reading progress indicator (percentage or "unread")

**Organization**:
- Filter by tags (if present in frontmatter or content)
- Search by title/content
- Sort by: date added, title, reading progress

**Actions**:
- Click to open article in reading view
- Manual refresh button to reload files from folder

### 2. Reading View

A distraction-free reading experience.

**Typography**:
- Clean, readable serif or sans-serif font
- Comfortable line width (50-75 characters)
- Proper line height and paragraph spacing
- Responsive text sizing

**Customization**:
- Font family selection (2-3 options)
- Font size adjustment (slider or presets)
- Line spacing options
- Margin/width adjustment

**Navigation**:
- Keyboard shortcuts:
  - `Escape` or `Cmd+[` to return to library
  - `Space` / `Shift+Space` to scroll page
  - `j/k` or arrow keys to scroll
  - `g g` to go to top, `G` to go to bottom
- Optional table of contents sidebar (extracted from headings)

**Progress Tracking**:
- Automatically save scroll position
- Show reading progress in UI (percentage or progress bar)
- Resume where you left off when reopening

### 3. Article Metadata Panel (Optional)

A collapsible sidebar showing:
- Title
- Author
- Source URL (clickable to open in browser)
- Published date
- Word count / reading time
- Reading progress

---

## User Interface

### Window Layout

```
┌─────────────────────────────────────────────────────────┐
│  [Refresh]  [Search...]                    [Sort ▼]     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📄 Article Title                          12 min       │
│     Author · source.com                    ████░░ 67%   │
│                                                         │
│  📄 Another Article                        5 min        │
│     Author · another.com                   Unread       │
│                                                         │
│  ...                                                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Reading View Layout

```
┌─────────────────────────────────────────────────────────┐
│  [← Back]                              [Aa] [Info]      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│              Article Title                              │
│              Author · 12 min read                       │
│                                                         │
│              Article content with clean                 │
│              typography and comfortable                 │
│              reading width...                           │
│                                                         │
│              ████████████░░░░░░░░░░░░░ 45%             │
└─────────────────────────────────────────────────────────┘
```

---

## Data Persistence

**What to persist** (locally, in app storage):
- Reading progress for each article (scroll position / percentage)
- User preferences (font, size, etc.)
- Article status (read/unread)

**What NOT to persist**:
- Article content (always read from source .md files)
- Notes/highlights (out of scope for MVP)

---

## Out of Scope (MVP)

- Dark mode
- Note-taking / highlighting
- Syncing across devices
- Automatic folder watching (manual refresh only)
- Editing articles
- Multiple folder sources
- Export functionality
- Browser extension integration

---

## Success Criteria

1. Can browse all markdown files in the Clippings folder
2. Clean, readable typography in reading view
3. Reading progress is saved and restored
4. Keyboard navigation works smoothly
5. App feels native and responsive

---

## Future Considerations

These may be added after MVP:
- Folder watching for auto-refresh
- Multiple source folders
- Tag management
- Reading statistics
- Full-text search with highlighting
- Table of contents sidebar
- Archiving/organizing articles within the app
