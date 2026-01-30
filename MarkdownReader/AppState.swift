import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var selectedArticle: Article?
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .dateAdded

    private let articleService = ArticleService()
    private let progressStore = ReadingProgressStore()

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case title = "Title"
        case progress = "Progress"
    }

    var filteredArticles: [Article] {
        var result = articles

        if !searchText.isEmpty {
            result = result.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        switch sortOrder {
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .title:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .progress:
            result.sort { ($0.readingProgress ?? 0) > ($1.readingProgress ?? 0) }
        }

        return result
    }

    func loadArticles() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var loadedArticles = try await articleService.loadArticles()

            // Load reading progress for each article
            for i in loadedArticles.indices {
                if let progress = progressStore.getProgress(for: loadedArticles[i].id) {
                    loadedArticles[i].readingProgress = progress.percentage
                    loadedArticles[i].scrollPosition = progress.scrollPosition
                }
            }

            articles = loadedArticles
        } catch {
            print("Error loading articles: \(error)")
        }
    }

    func saveProgress(for article: Article, percentage: Double, scrollPosition: Double) {
        progressStore.saveProgress(
            for: article.id,
            percentage: percentage,
            scrollPosition: scrollPosition
        )

        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].readingProgress = percentage
            articles[index].scrollPosition = scrollPosition
        }
    }

    func getProgress(for article: Article) -> ReadingProgress? {
        progressStore.getProgress(for: article.id)
    }
}
