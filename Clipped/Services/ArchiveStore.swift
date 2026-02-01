import Foundation

class ArchiveStore {
    private let userDefaults = UserDefaults.standard
    private let archiveKey = "archivedArticles"

    private var archivedIds: Set<String> = []

    init() {
        loadFromStorage()
    }

    func archive(_ articleId: String) {
        archivedIds.insert(articleId)
        saveToStorage()
    }

    func unarchive(_ articleId: String) {
        archivedIds.remove(articleId)
        saveToStorage()
    }

    func isArchived(_ articleId: String) -> Bool {
        archivedIds.contains(articleId)
    }

    func getAllArchived() -> Set<String> {
        archivedIds
    }

    private func loadFromStorage() {
        guard let data = userDefaults.data(forKey: archiveKey) else { return }

        do {
            let decoder = JSONDecoder()
            let ids = try decoder.decode([String].self, from: data)
            archivedIds = Set(ids)
        } catch {
            print("Error loading archived articles: \(error)")
        }
    }

    private func saveToStorage() {
        do {
            let encoder = JSONEncoder()
            let ids = Array(archivedIds)
            let data = try encoder.encode(ids)
            userDefaults.set(data, forKey: archiveKey)
        } catch {
            print("Error saving archived articles: \(error)")
        }
    }
}
