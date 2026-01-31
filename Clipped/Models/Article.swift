import Foundation

struct Article: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let author: String?
    let sourceURL: URL?
    let publishedDate: Date?
    let content: String
    let filePath: URL
    let dateAdded: Date
    let wordCount: Int
    let tags: [String]

    var readingProgress: Double?
    var scrollPosition: Double?

    var estimatedReadingTime: Int {
        // Average reading speed: 200-250 words per minute
        max(1, wordCount / 225)
    }

    var sourceDomain: String? {
        sourceURL?.host
    }

    var isUnread: Bool {
        readingProgress == nil || readingProgress == 0
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
