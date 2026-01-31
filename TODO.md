# Markdown Reader - Remaining Tasks

## Library View

- [ ] Filter by tags (if present in frontmatter or content)
- [ ] Visual progress bar indicator (currently just percentage text)

## Reading View

### Keyboard Shortcuts
- [ ] `Escape` or `Cmd+[` to return to library
- [ ] `Space` / `Shift+Space` to scroll page
- [ ] `j/k` or arrow keys to scroll
- [ ] `g g` to go to top, `G` to go to bottom

### Scroll & Progress
- [ ] Scroll position restoration on reopen (partially implemented, needs testing)
- [ ] Verify progress saves correctly when closing article

### Markdown Rendering
- [ ] Code blocks with syntax highlighting
- [ ] Images
- [ ] Horizontal rules
- [ ] Better inline formatting (bold, italic, inline code)

## Article Metadata Panel (Optional)

- [ ] Collapsible sidebar showing:
  - Title
  - Author
  - Source URL (clickable to open in browser)
  - Published date
  - Word count / reading time
  - Reading progress

## Data Persistence

- [ ] Verify read/unread status tracking works correctly
- [ ] Test progress persistence across app restarts

## Polish

- [ ] Window title and default sizing
- [ ] Empty state when no articles found in folder
- [ ] Error handling when Clippings folder doesn't exist
- [ ] Refine typography defaults for distraction-free reading
- [ ] Loading states during article refresh
