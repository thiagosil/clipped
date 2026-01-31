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
        VStack(spacing: 8) {
            // Top row with controls
            HStack(spacing: 10) {
                // Tag filter dropdown
                if !appState.allTags.isEmpty {
                    tagFilterMenu
                }

                Spacer()

                // Pick for Me button
                Button(action: {
                    if let article = appState.pickRandomArticle() {
                        withAnimation(.easeOut(duration: 0.15)) {
                            appState.selectedArticle = article
                        }
                    }
                }) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.sidebarIcon)
                .help("Pick a random article")
                .disabled(appState.filteredArticles.isEmpty)

                // Sort picker
                sortMenu

                // Refresh button
                Button(action: {
                    Task { await appState.loadArticles() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .tint(Theme.sidebarIcon)
                .foregroundColor(Theme.sidebarIcon)
                .help("Refresh articles")
            }

            // Search field
            searchField
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
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
        }
        .menuStyle(.borderlessButton)
        .tint(appState.selectedTags.isEmpty ? Theme.sidebarIcon : Theme.accent)
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
        }
        .menuStyle(.borderlessButton)
        .tint(Theme.sidebarIcon)
        .fixedSize()
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.searchPlaceholder)

            ZStack(alignment: .leading) {
                if appState.searchText.isEmpty {
                    Text("Search...")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.searchPlaceholder)
                }
                TextField("", text: $appState.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.listText)
            }

            if !appState.searchText.isEmpty {
                Button(action: { appState.searchText = "" }) {
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
                .stroke(Theme.searchBorder, lineWidth: 1)
        )
    }

    // MARK: - Active Filters

    private var activeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(appState.selectedTags).sorted(), id: \.self) { tag in
                    HStack(spacing: 3) {
                        Text(tag)
                            .font(.system(size: 10, weight: .medium))
                        Button(action: { appState.toggleTag(tag) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.accentSubtle)
                    .foregroundColor(Theme.accent)
                    .clipShape(Capsule())
                }

                Button("Clear") {
                    appState.clearTagFilters()
                }
                .font(.system(size: 10))
                .foregroundColor(Theme.listSecondaryText)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
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
                                    articleRow(for: article)
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
                                    articleRow(for: article)
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
                                    articleRow(for: article)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func articleRow(for article: Article) -> some View {
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
