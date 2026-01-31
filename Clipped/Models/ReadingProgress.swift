import Foundation

struct ReadingProgress: Codable {
    let articleId: String
    var percentage: Double
    var scrollPosition: Double
    var lastReadDate: Date

    init(articleId: String, percentage: Double, scrollPosition: Double) {
        self.articleId = articleId
        self.percentage = percentage
        self.scrollPosition = scrollPosition
        self.lastReadDate = Date()
    }
}
