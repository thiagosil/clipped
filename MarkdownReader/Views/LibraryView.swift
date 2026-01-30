import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: {
                    Task {
                        await appState.loadArticles()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh articles")

                // Tag filter menu
                if !appState.allTags.isEmpty {
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
                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                            if !appState.selectedTags.isEmpty {
                                Text("\(appState.selectedTags.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .help("Filter by tags")
                }

                Spacer()

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search...", text: $appState.searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 150)
                    if !appState.searchText.isEmpty {
                        Button(action: { appState.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)

                // Sort picker
                Picker("Sort", selection: $appState.sortOrder) {
                    ForEach(AppState.SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            .padding()

            // Active tag filters display
            if !appState.selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(appState.selectedTags).sorted(), id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Button(action: { appState.toggleTag(tag) }) {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                        }

                        Button("Clear all") {
                            appState.clearTagFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }

            Divider()

            // Article list
            if appState.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading articles...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = appState.loadError {
                errorView(for: error)
            } else if appState.articles.isEmpty {
                emptyStateView(message: "No articles found",
                              detail: "Add markdown files to your Clippings folder",
                              icon: "doc.text")
            } else if appState.filteredArticles.isEmpty {
                emptyStateView(message: "No matching articles",
                              detail: "Try adjusting your search or filters",
                              icon: "magnifyingglass")
            } else {
                List(appState.filteredArticles, selection: Binding(
                    get: { appState.selectedArticle },
                    set: { appState.selectedArticle = $0 }
                )) { article in
                    ArticleRow(article: article)
                        .tag(article)
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 300)
    }

    @ViewBuilder
    private func emptyStateView(message: String, detail: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))

            if !appState.searchText.isEmpty || !appState.selectedTags.isEmpty {
                Button("Clear Filters") {
                    appState.searchText = ""
                    appState.clearTagFilters()
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func errorView(for error: ArticleServiceError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            switch error {
            case .folderNotFound:
                Text("Clippings folder not found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Please ensure the folder exists at:\n~/Documents/ObsidianPKM/Clippings")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            case .parsingError:
                Text("Error reading articles")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Some files could not be parsed")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.8))
            }

            Button("Try Again") {
                Task {
                    await appState.loadArticles()
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ArticleRow: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()

                Text("\(article.estimatedReadingTime) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                if let author = article.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if article.sourceDomain != nil {
                        Text("·")
                            .foregroundColor(.secondary)
                    }
                }

                if let domain = article.sourceDomain {
                    Text(domain)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress indicator
                if article.isUnread {
                    Text("Unread")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let progress = article.readingProgress {
                    ProgressView(value: progress / 100)
                        .frame(width: 60)
                        .tint(progress >= 100 ? .green : .accentColor)
                    Text("\(Int(progress))%")
                        .font(.caption)
                        .foregroundColor(progress >= 100 ? .green : .secondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }

            // Tags
            if !article.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(article.tags.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                        if article.tags.count > 5 {
                            Text("+\(article.tags.count - 5)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
