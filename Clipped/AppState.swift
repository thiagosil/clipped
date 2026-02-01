import SwiftUI
import AppKit

@MainActor
class AppState: ObservableObject {
    @Published var selectedArticle: Article?
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .dateAdded
    @Published var selectedTags: Set<String> = []
    @Published var loadError: ArticleServiceError?
    @Published var collapsedSections: Set<SmartSurface> = [.theStack]
    @Published var showKeyboardShortcuts = false
    @Published var sidebarVisible = true
    @Published var showReadwiseImport = false

    private let articleService = ArticleService()
    private let progressStore = ReadingProgressStore()
    private let archiveStore = ArchiveStore()
    let folderSettings = FolderSettingsStore()
    let readwiseSettings = ReadwiseSettingsStore()

    @Published var archivedArticleIds: Set<String> = []

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case title = "Title"
        case progress = "Progress"
    }

    enum SmartSurface: String, CaseIterable {
        case continueReading = "Continue"
        case quickWins = "Quick Wins"
        case theStack = "The Stack"
        case archived = "Archived"
    }

    var allTags: [String] {
        let tagSet = Set(articles.flatMap { $0.tags })
        return Array(tagSet).sorted()
    }

    var filteredArticles: [Article] {
        var result = articles

        // Exclude archived articles
        result = result.filter { !archivedArticleIds.contains($0.id) }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                article.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Filter by selected tags
        if !selectedTags.isEmpty {
            result = result.filter { article in
                !selectedTags.isDisjoint(with: Set(article.tags))
            }
        }

        // Sort results
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

    var archivedArticles: [Article] {
        var result = articles.filter { archivedArticleIds.contains($0.id) }

        // Apply same search/tag filters
        if !searchText.isEmpty {
            result = result.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                (article.author?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                article.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        if !selectedTags.isEmpty {
            result = result.filter { article in
                !selectedTags.isDisjoint(with: Set(article.tags))
            }
        }

        // Sort by date added
        result.sort { $0.dateAdded > $1.dateAdded }

        return result
    }

    var continueReadingArticles: [Article] {
        filteredArticles
            .filter {
                guard let progress = $0.readingProgress else { return false }
                return progress > 0 && progress < 100
            }
            .sorted { ($0.readingProgress ?? 0) > ($1.readingProgress ?? 0) }
    }

    var quickWinsArticles: [Article] {
        filteredArticles
            .filter { $0.isUnread && $0.estimatedReadingTime <= 5 }
            .sorted { $0.estimatedReadingTime < $1.estimatedReadingTime }
    }

    var theStackArticles: [Article] {
        let continueIds = Set(continueReadingArticles.map { $0.id })
        let quickWinIds = Set(quickWinsArticles.map { $0.id })
        return filteredArticles.filter { article in
            !continueIds.contains(article.id) && !quickWinIds.contains(article.id)
        }
    }

    func loadArticles() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        guard let folderPath = folderSettings.folderPath else {
            loadError = .noFolderConfigured
            return
        }

        do {
            var loadedArticles = try await articleService.loadArticles(from: folderPath)

            // Load reading progress for each article
            for i in loadedArticles.indices {
                if let progress = progressStore.getProgress(for: loadedArticles[i].id) {
                    loadedArticles[i].readingProgress = progress.percentage
                    loadedArticles[i].scrollPosition = progress.scrollPosition
                }
            }

            articles = loadedArticles
            archivedArticleIds = archiveStore.getAllArchived()
            loadSectionState()
        } catch let error as ArticleServiceError {
            loadError = error
            print("Error loading articles: \(error)")
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

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func clearTagFilters() {
        selectedTags.removeAll()
    }

    func archiveArticle(_ article: Article) {
        archiveStore.archive(article.id)
        archivedArticleIds.insert(article.id)
        if selectedArticle?.id == article.id {
            selectedArticle = nil
        }
    }

    func unarchiveArticle(_ article: Article) {
        archiveStore.unarchive(article.id)
        archivedArticleIds.remove(article.id)
    }

    func isArchived(_ article: Article) -> Bool {
        archivedArticleIds.contains(article.id)
    }

    func toggleSection(_ section: SmartSurface) {
        if collapsedSections.contains(section) {
            collapsedSections.remove(section)
        } else {
            collapsedSections.insert(section)
        }
        saveSectionState()
    }

    func pickRandomArticle() -> Article? {
        var pool: [Article] = []
        pool.append(contentsOf: continueReadingArticles)
        pool.append(contentsOf: continueReadingArticles)
        pool.append(contentsOf: continueReadingArticles)
        pool.append(contentsOf: quickWinsArticles)
        pool.append(contentsOf: quickWinsArticles)
        pool.append(contentsOf: theStackArticles)
        return pool.randomElement()
    }

    private func saveSectionState() {
        UserDefaults.standard.set(
            collapsedSections.map { $0.rawValue },
            forKey: "collapsedSections"
        )
    }

    func loadSectionState() {
        if let collapsed = UserDefaults.standard.stringArray(forKey: "collapsedSections") {
            collapsedSections = Set(collapsed.compactMap { SmartSurface(rawValue: $0) })
        }
    }

    func nextUnreadArticle(after current: Article?) -> Article? {
        let unread = filteredArticles.filter { ($0.readingProgress ?? 0) < 100 }
        guard let current = current,
              let currentIndex = filteredArticles.firstIndex(where: { $0.id == current.id }) else {
            return unread.first
        }
        // Find next unread after current position
        let afterCurrent = filteredArticles.suffix(from: filteredArticles.index(after: currentIndex))
        return afterCurrent.first { ($0.readingProgress ?? 0) < 100 } ?? unread.first
    }

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder containing your markdown articles"
        panel.prompt = "Choose"

        if let currentPath = folderSettings.folderPath {
            panel.directoryURL = URL(fileURLWithPath: currentPath)
        }

        if panel.runModal() == .OK, let url = panel.url {
            folderSettings.folderPath = url.path
            Task {
                await loadArticles()
            }
        }
    }
}
