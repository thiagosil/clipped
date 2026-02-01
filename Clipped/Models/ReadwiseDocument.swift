import Foundation

struct ReadwiseDocument: Codable, Identifiable {
    let id: String
    let title: String?
    let author: String?
    let url: String?
    let sourceURL: String?
    let html: String?
    let content: String?
    let summary: String?
    let publishedDate: Date?
    let createdAt: Date?
    let updatedAt: Date?
    let location: String?
    let category: String?
    let tags: [Tag]?
    let readingProgress: Double?
    let parentId: String?
    let siteName: String?
    let wordCount: Int?
    let notes: String?

    struct Tag: Codable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case url
        case sourceURL = "source_url"
        case html
        case content
        case summary
        case publishedDate = "published_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case location
        case category
        case tags
        case readingProgress = "reading_progress"
        case parentId = "parent_id"
        case siteName = "site_name"
        case wordCount = "word_count"
        case notes
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
