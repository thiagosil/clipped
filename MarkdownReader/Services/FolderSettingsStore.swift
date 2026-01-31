import Foundation

class FolderSettingsStore: ObservableObject {
    private let folderPathKey = "selectedFolderPath"

    @Published var folderPath: String? {
        didSet {
            if let path = folderPath {
                UserDefaults.standard.set(path, forKey: folderPathKey)
            } else {
                UserDefaults.standard.removeObject(forKey: folderPathKey)
            }
        }
    }

    var folderURL: URL? {
        guard let path = folderPath else { return nil }
        return URL(fileURLWithPath: path)
    }

    var folderDisplayName: String? {
        guard let path = folderPath else { return nil }
        return (path as NSString).lastPathComponent
    }

    init() {
        self.folderPath = UserDefaults.standard.string(forKey: folderPathKey)
    }
}
