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

                Spacer()

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search...", text: $appState.searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 150)
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

            Divider()

            // Article list
            if appState.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.filteredArticles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No articles found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    Text("\(Int(progress))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
