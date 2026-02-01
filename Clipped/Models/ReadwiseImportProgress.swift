import Foundation

struct ReadwiseImportProgress: Sendable {
    let totalCount: Int?
    let fetchedCount: Int
    let currentPage: Int
    let status: Status
    let newCount: Int
    let skippedCount: Int

    init(
        totalCount: Int?,
        fetchedCount: Int,
        currentPage: Int,
        status: Status,
        newCount: Int = 0,
        skippedCount: Int = 0
    ) {
        self.totalCount = totalCount
        self.fetchedCount = fetchedCount
        self.currentPage = currentPage
        self.status = status
        self.newCount = newCount
        self.skippedCount = skippedCount
    }

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
            if skippedCount > 0 {
                return "\(newCount) new articles imported, \(skippedCount) already existed."
            } else if newCount > 0 {
                return "\(newCount) new articles imported."
            } else {
                return "No new articles to import."
            }
        case .failed(let message):
            return "Import failed: \(message)"
        }
    }
}
