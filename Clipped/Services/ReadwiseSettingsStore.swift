import Foundation

class ReadwiseSettingsStore: ObservableObject {
    private let apiKeyKey = "readwiseApiKey"

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
}
