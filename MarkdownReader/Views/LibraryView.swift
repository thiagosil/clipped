import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var hoveredArticle: Article?

    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            header

            // Tag filters (if any active)
            if !appState.selectedTags.isEmpty {
                activeFilters
            }

            // Article list
            articleList
        }
        .background(Theme.listBackground)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            // Top row with title and controls
            HStack(spacing: 12) {
                // Tag filter dropdown
                if !appState.allTags.isEmpty {
                    tagFilterMenu
                }

                Spacer()

                // Sort picker
                sortMenu

                // Refresh button
                Button(action: {
                    Task { await appState.loadArticles() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.sidebarIcon)
                }
                .buttonStyle(.plain)
                .help("Refresh articles")
            }

            // Search field
            searchField
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var tagFilterMenu: some View {
        Menu {
            if !appState.selectedTags.isEmpty {
                Button("Clear Filters") {
                    appState.clearTagFilters()
                }
                Divider()
            }

            ForEach(appState.allTags, id: \.self) { tag in
                Button {
                    appState.toggleTag(tag)
                } label: {
                    HStack {
                        Text(tag)
                        if appState.selectedTags.contains(tag) {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "number")
                    .font(.system(size: 12, weight: .semibold))
                if !appState.selectedTags.isEmpty {
                    Text("\(appState.selectedTags.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.accent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(appState.selectedTags.isEmpty ? Theme.sidebarIcon : Theme.accent)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var sortMenu: some View {
        Menu {
            ForEach(AppState.SortOrder.allCases, id: \.self) { order in
                Button {
                    appState.sortOrder = order
                } label: {
                    HStack {
                        Text(order.rawValue)
                        if appState.sortOrder == order {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.sidebarIcon)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.searchPlaceholder)

            TextField("Search articles...", text: $appState.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(Theme.listText)

            if !appState.searchText.isEmpty {
                Button(action: { appState.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.searchPlaceholder)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.searchBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.searchBorder, lineWidth: 1)
        )
    }

    // MARK: - Active Filters

    private var activeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(appState.selectedTags).sorted(), id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                        Button(action: { appState.toggleTag(tag) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.accentSubtle)
                    .foregroundColor(Theme.accent)
                    .clipShape(Capsule())
                }

                Button("Clear") {
                    appState.clearTagFilters()
                }
                .font(.system(size: 11))
                .foregroundColor(Theme.listSecondaryText)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Article List

    private var articleList: some View {
        Group {
            if appState.isLoading {
                loadingView
            } else if let error = appState.loadError {
                errorView(for: error)
            } else if appState.articles.isEmpty {
                emptyStateView(
                    icon: "doc.text",
                    title: "No articles",
                    subtitle: "Add markdown files to your Clippings folder"
                )
            } else if appState.filteredArticles.isEmpty {
                emptyStateView(
                    icon: "magnifyingglass",
                    title: "No results",
                    subtitle: "Try adjusting your search or filters"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.filteredArticles) { article in
                            ArticleRow(
                                article: article,
                                isSelected: appState.selectedArticle?.id == article.id,
                                isHovered: hoveredArticle?.id == article.id
                            )
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    appState.selectedArticle = article
                                }
                            }
                            .onHover { hovering in
                                hoveredArticle = hovering ? article : nil
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.listSecondaryText))
                .scaleEffect(0.8)
            Text("Loading...")
                .font(.system(size: 13))
                .foregroundColor(Theme.listSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(Theme.listTertiaryText)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.listSecondaryText)

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(Theme.listTertiaryText)
                .multilineTextAlignment(.center)

            if !appState.searchText.isEmpty || !appState.selectedTags.isEmpty {
                Button("Clear Filters") {
                    appState.searchText = ""
                    appState.clearTagFilters()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.accent)
                .padding(.top, 4)
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(for error: ArticleServiceError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(Theme.accent)

            switch error {
            case .folderNotFound:
                Text("Folder not found")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.listSecondaryText)
                Text("~/Documents/ObsidianPKM/Clippings")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.listTertiaryText)
            case .parsingError:
                Text("Error reading articles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.listSecondaryText)
            }

            Button("Try Again") {
                Task { await appState.loadArticles() }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Theme.accent)
            .padding(.top, 4)
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Article Row

struct ArticleRow: View {
    let article: Article
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Title - larger and bolder like Bear
                Text(article.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.listText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Content preview - 2 lines of article text
                Text(contentPreview)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : Theme.listSecondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Date
                Text(formatDate(article.dateAdded))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.5) : Theme.listTertiaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Separator line (only if not selected)
            if !isSelected {
                Rectangle()
                    .fill(Theme.sidebarDivider)
                    .frame(height: 1)
                    .padding(.leading, 20)
            }
        }
        .background(backgroundColor)
        .contentShape(Rectangle())
    }

    // Extract first ~120 characters of content, stripping markdown
    private var contentPreview: String {
        var preview = article.content
            // Remove frontmatter
            .replacingOccurrences(of: #"---[\s\S]*?---"#, with: "", options: .regularExpression)
            // Remove headers (# at line start)
            .replacingOccurrences(of: #"#+\s+"#, with: "", options: .regularExpression)
            // Remove links, keep text
            .replacingOccurrences(of: #"\[([^\]]+)\]\([^\)]+\)"#, with: "$1", options: .regularExpression)
            // Remove images
            .replacingOccurrences(of: #"!\[([^\]]*)\]\([^\)]+\)"#, with: "", options: .regularExpression)
            // Remove bold/italic markers
            .replacingOccurrences(of: #"\*\*([^\*]+)\*\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\*([^\*]+)\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"_([^_]+)_"#, with: "$1", options: .regularExpression)
            // Remove code blocks
            .replacingOccurrences(of: #"```[\s\S]*?```"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"`[^`]+`"#, with: "", options: .regularExpression)
            // Remove blockquotes marker
            .replacingOccurrences(of: #">\s*"#, with: "", options: .regularExpression)
            // Remove list markers
            .replacingOccurrences(of: #"[-*]\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\d+\.\s+"#, with: "", options: .regularExpression)
            // Collapse whitespace
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)

        // Truncate to ~120 chars at word boundary
        if preview.count > 120 {
            let truncated = String(preview.prefix(120))
            if let lastSpace = truncated.lastIndex(of: " ") {
                preview = String(truncated[..<lastSpace]) + "…"
            } else {
                preview = truncated + "…"
            }
        }

        return preview.isEmpty ? "No preview available" : preview
    }

    private var backgroundColor: Color {
        if isSelected {
            return Theme.listItemSelected
        } else if isHovered {
            return Theme.listItemHover
        } else {
            return Color.clear
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
}
