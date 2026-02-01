import Foundation

struct ReadwiseImportProgress: Sendable {
    let totalCount: Int?
    let fetchedCount: Int
    let currentPage: Int
    let status: Status

    enum Status: Sendable {
        case fetching
        case converting(articleTitle: String)
        case rateLimited(retryAfter: Int)
        case completed
        case failed(String)
    }

    var progressPercentage: Double? {
        guard let total = totalCount, total > 0 else { return nil }
        return Double(fetchedCount) / Double(total) * 100
    }

    var statusText: String {
        switch status {
        case .fetching:
            if let total = totalCount {
                return "Fetching articles... \(fetchedCount) of \(total)"
            } else {
                return "Fetching articles... \(fetchedCount)"
            }
        case .converting(let title):
            return "Converting: \(title)"
        case .rateLimited(let seconds):
            return "Rate limited. Waiting \(seconds) seconds..."
        case .completed:
            return "Import completed! \(fetchedCount) articles imported."
        case .failed(let message):
            return "Import failed: \(message)"
        }
    }
}
