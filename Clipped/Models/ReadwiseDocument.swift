import Foundation

struct ReadwiseDocument: Codable, Identifiable {
    let id: String
    let title: String?
    let author: String?
    let url: String?
    let sourceURL: String?
    let source: String?
    let html: String?
    let htmlContent: String?
    let content: String?
    let summary: String?
    let publishedDate: String?  // Keep as String, parse manually if needed
    let createdAt: String?
    let updatedAt: String?
    let savedAt: String?
    let lastMovedAt: String?
    let firstOpenedAt: String?
    let lastOpenedAt: String?
    let location: String?
    let category: String?
    let tags: [String: TagInfo]?  // Changed from [Tag]? to dictionary
    let readingProgress: Double?
    let parentId: String?
    let siteName: String?
    let wordCount: Int?
    let readingTime: String?
    let notes: String?
    let imageUrl: String?

    struct TagInfo: Codable {
        // Tags are objects with tag name as key
        // The value might be empty or contain metadata
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case url
        case sourceURL = "source_url"
        case source
        case html
        case htmlContent = "html_content"
        case content
        case summary
        case publishedDate = "published_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case savedAt = "saved_at"
        case lastMovedAt = "last_moved_at"
        case firstOpenedAt = "first_opened_at"
        case lastOpenedAt = "last_opened_at"
        case location
        case category
        case tags
        case readingProgress = "reading_progress"
        case parentId = "parent_id"
        case siteName = "site_name"
        case wordCount = "word_count"
        case readingTime = "reading_time"
        case notes
        case imageUrl = "image_url"
    }

    // Helper to get tag names as array
    var tagNames: [String] {
        guard let tags = tags else { return [] }
        return Array(tags.keys)
    }
}

struct ReadwiseListResponse: Codable {
    let count: Int?
    let nextPageCursor: String?
    let results: [ReadwiseDocument]

    enum CodingKeys: String, CodingKey {
        case count
        case nextPageCursor
        case results
    }
}
