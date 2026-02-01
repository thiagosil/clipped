import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var hoveredArticle: Article?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header controls
            header

            // Article list
            articleList

            // Search at bottom - only focused when clicked
            searchField
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .background(Theme.listBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Spacer()

            // Sort picker
            sortMenu

            // More actions menu
            moreActionsMenu
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var moreActionsMenu: some View {
        Menu {
            Button {
                if let article = appState.pickRandomArticle() {
                    withAnimation(.easeOut(duration: 0.15)) {
                        appState.selectedArticle = article
                    }
                }
            } label: {
                Label("Pick Random", systemImage: "shuffle")
            }
            .disabled(appState.filteredArticles.isEmpty)

            Divider()

            Button {
                Task { await appState.loadArticles() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: .command)

            Button {
                appState.showReadwiseImport = true
            } label: {
                Label("Import from Readwise", systemImage: "square.and.arrow.down")
            }

            Divider()

            Button {
                appState.selectFolder()
            } label: {
                Label("Change Folder...", systemImage: "folder")
            }
            .keyboardShortcut("o", modifiers: .command)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 12, weight: .medium))
        }
        .menuStyle(.borderlessButton)
        .tint(Theme.sidebarIcon)
        .fixedSize()
        .help("More actions (⌘R refresh, ⌘O folder)")
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
            HStack(spacing: 4) {
                Image(systemName: sortIcon)
                    .font(.system(size: 12, weight: .medium))
                Text(sortLabel)
                    .font(.system(size: 11))
            }
        }
        .menuStyle(.borderlessButton)
        .tint(Theme.sidebarIcon)
        .fixedSize()
        .help("Sort articles")
    }

    private var sortIcon: String {
        switch appState.sortOrder {
        case .dateAdded: return "calendar"
        case .title: return "textformat"
        case .progress: return "chart.bar.fill"
        }
    }

    private var sortLabel: String {
        switch appState.sortOrder {
        case .dateAdded: return "Date"
        case .title: return "Title"
        case .progress: return "Progress"
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.searchPlaceholder)

            ZStack(alignment: .leading) {
                if appState.searchText.isEmpty && !isSearchFocused {
                    Text("Search...")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.searchPlaceholder)
                }
                TextField("", text: $appState.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.listText)
                    .focused($isSearchFocused)
            }

            if !appState.searchText.isEmpty {
                Button(action: {
                    appState.searchText = ""
                    isSearchFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.searchPlaceholder)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Theme.searchBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSearchFocused ? Theme.accent : Theme.searchBorder, lineWidth: 1)
        )
        .onTapGesture {
            isSearchFocused = true
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
                        // Continue section
                        if !appState.continueReadingArticles.isEmpty {
                            SectionHeader(
                                title: "Continue",
                                icon: "book.fill",
                                count: appState.continueReadingArticles.count,
                                isCollapsed: appState.collapsedSections.contains(.continueReading),
                                onToggle: { appState.toggleSection(.continueReading) }
                            )
                            if !appState.collapsedSections.contains(.continueReading) {
                                ForEach(appState.continueReadingArticles) { article in
                                    articleRow(for: article, isArchived: false)
                                }
                            }
                        }

                        // Quick Wins section
                        if !appState.quickWinsArticles.isEmpty {
                            SectionHeader(
                                title: "Quick Wins",
                                icon: "bolt.fill",
                                count: appState.quickWinsArticles.count,
                                isCollapsed: appState.collapsedSections.contains(.quickWins),
                                onToggle: { appState.toggleSection(.quickWins) }
                            )
                            if !appState.collapsedSections.contains(.quickWins) {
                                ForEach(appState.quickWinsArticles) { article in
                                    articleRow(for: article, isArchived: false)
                                }
                            }
                        }

                        // The Stack section
                        if !appState.theStackArticles.isEmpty {
                            SectionHeader(
                                title: "The Stack",
                                icon: "books.vertical.fill",
                                count: appState.theStackArticles.count,
                                isCollapsed: appState.collapsedSections.contains(.theStack),
                                onToggle: { appState.toggleSection(.theStack) }
                            )
                            if !appState.collapsedSections.contains(.theStack) {
                                ForEach(appState.theStackArticles) { article in
                                    articleRow(for: article, isArchived: false)
                                }
                            }
                        }

                        // Archived section
                        if !appState.archivedArticles.isEmpty {
                            SectionHeader(
                                title: "Archived",
                                icon: "archivebox.fill",
                                count: appState.archivedArticles.count,
                                isCollapsed: appState.collapsedSections.contains(.archived),
                                onToggle: { appState.toggleSection(.archived) }
                            )
                            if !appState.collapsedSections.contains(.archived) {
                                ForEach(appState.archivedArticles) { article in
                                    articleRow(for: article, isArchived: true)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func articleRow(for article: Article, isArchived: Bool) -> some View {
        ArticleRow(
            article: article,
            isSelected: appState.selectedArticle?.id == article.id,
            isHovered: hoveredArticle?.id == article.id
        )
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.1)) {
                appState.selectedArticle = article
            }
        }
        .onHover { hovering in
            hoveredArticle = hovering ? article : nil
        }
        .contextMenu {
            if isArchived {
                Button {
                    appState.unarchiveArticle(article)
                } label: {
                    Label("Unarchive", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button {
                    appState.archiveArticle(article)
                } label: {
                    Label("Archive", systemImage: "archivebox")
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
            switch error {
            case .noFolderConfigured:
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Theme.listTertiaryText)

                Text("No folder selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.listSecondaryText)

                Text("Choose a folder containing your markdown articles")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.listTertiaryText)
                    .multilineTextAlignment(.center)

                Button("Choose Folder...") {
                    appState.selectFolder()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.accent)
                .padding(.top, 4)
                .buttonStyle(.plain)

            case .folderNotFound(let path):
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Theme.accent)

                Text("Folder not found")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.listSecondaryText)

                Text(path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.listTertiaryText)
                    .lineLimit(2)
                    .truncationMode(.middle)

                Button("Choose Different Folder...") {
                    appState.selectFolder()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.accent)
                .padding(.top, 4)
                .buttonStyle(.plain)

            case .parsingError:
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Theme.accent)

                Text("Error reading articles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.listSecondaryText)

                Button("Try Again") {
                    Task { await appState.loadArticles() }
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
}

// MARK: - Article Row (Compact Two-Line)

struct ArticleRow: View {
    let article: Article
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Slim selection indicator
            Rectangle()
                .fill(isSelected ? Theme.accent : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                // Top line: Title + Checkmark + Date
                HStack(spacing: 8) {
                    Text(article.title)
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                        .foregroundColor(Theme.listText)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if (article.readingProgress ?? 0) >= 100 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.progressComplete)
                    }

                    Text(compactDate(article.dateAdded))
                        .font(.system(size: 11))
                        .foregroundColor(Theme.listTertiaryText)
                }

                // Bottom line: Author · Source
                if let subtitle = sourceSubtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.listSecondaryText)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
        }
        .background(backgroundColor)
        .contentShape(Rectangle())
    }

    private var sourceSubtitle: String? {
        let author = article.author
        let domain = article.sourceDomain?.replacingOccurrences(of: "www.", with: "")

        switch (author, domain) {
        case let (a?, d?):
            return "\(a) · \(d)"
        case let (a?, nil):
            return a
        case let (nil, d?):
            return d
        case (nil, nil):
            return nil
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Theme.listItemSelectedSubtle
        } else if isHovered {
            return Theme.listItemHover
        } else {
            return Color.clear
        }
    }

    private func compactDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yest"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d/M"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    let count: Int
    let isCollapsed: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Theme.listTertiaryText)
                    .frame(width: 10)

                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.listSecondaryText)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.listSecondaryText)

                Text("\(count)")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.listTertiaryText)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.listBackground.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
}
