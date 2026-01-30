import Foundation

class ReadingProgressStore {
    private let userDefaults = UserDefaults.standard
    private let progressKey = "readingProgress"

    private var progressCache: [String: ReadingProgress] = [:]

    init() {
        loadFromStorage()
    }

    func saveProgress(for articleId: String, percentage: Double, scrollPosition: Double) {
        let progress = ReadingProgress(
            articleId: articleId,
            percentage: percentage,
            scrollPosition: scrollPosition
        )
        progressCache[articleId] = progress
        saveToStorage()
    }

    func getProgress(for articleId: String) -> ReadingProgress? {
        progressCache[articleId]
    }

    func getAllProgress() -> [String: ReadingProgress] {
        progressCache
    }

    private func loadFromStorage() {
        guard let data = userDefaults.data(forKey: progressKey) else { return }

        do {
            let decoder = JSONDecoder()
            let progressArray = try decoder.decode([ReadingProgress].self, from: data)
            progressCache = Dictionary(uniqueKeysWithValues: progressArray.map { ($0.articleId, $0) })
        } catch {
            print("Error loading reading progress: \(error)")
        }
    }

    private func saveToStorage() {
        do {
            let encoder = JSONEncoder()
            let progressArray = Array(progressCache.values)
            let data = try encoder.encode(progressArray)
            userDefaults.set(data, forKey: progressKey)
        } catch {
            print("Error saving reading progress: \(error)")
        }
    }
}
