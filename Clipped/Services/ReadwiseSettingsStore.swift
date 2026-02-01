import Foundation

class ReadwiseSettingsStore: ObservableObject {
    private let apiKeyKey = "readwiseApiKey"
    private let lastImportDateKeyPrefix = "readwiseLastImport_"

    @Published var apiKey: String? {
        didSet {
            if let key = apiKey {
                UserDefaults.standard.set(key, forKey: apiKeyKey)
            } else {
                UserDefaults.standard.removeObject(forKey: apiKeyKey)
            }
        }
    }

    var hasAPIKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }

    init() {
        self.apiKey = UserDefaults.standard.string(forKey: apiKeyKey)
    }

    /// Get the last import date for a specific location
    func lastImportDate(for location: String) -> Date? {
        UserDefaults.standard.object(forKey: lastImportDateKeyPrefix + location) as? Date
    }

    /// Save the last import date for a specific location
    func setLastImportDate(_ date: Date, for location: String) {
        UserDefaults.standard.set(date, forKey: lastImportDateKeyPrefix + location)
    }

    /// Clear the last import date for a specific location (for full re-import)
    func clearLastImportDate(for location: String) {
        UserDefaults.standard.removeObject(forKey: lastImportDateKeyPrefix + location)
    }
}
