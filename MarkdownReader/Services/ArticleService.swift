import Foundation

actor ArticleService {
    private let clippingsPath = "/Users/thiago/Documents/ObsidianPKM/Clippings"

    func loadArticles() throws -> [Article] {
        let folderURL = URL(fileURLWithPath: clippingsPath)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: clippingsPath) else {
            throw ArticleServiceError.folderNotFound
        }

        let contents = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )

        let markdownFiles = contents.filter { $0.pathExtension == "md" }

        return markdownFiles.compactMap { fileURL in
            try? parseArticle(from: fileURL)
        }
    }

    private func parseArticle(from fileURL: URL) throws -> Article {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let dateAdded = (attributes[.creationDate] as? Date) ?? Date()

        let (frontmatter, bodyContent) = parseFrontmatter(from: content)

        let title = extractTitle(from: bodyContent, filename: fileURL.deletingPathExtension().lastPathComponent)
        let author = extractAuthor(from: frontmatter)
        let sourceURL = extractSourceURL(from: frontmatter)
        let publishedDate = extractPublishedDate(from: frontmatter)
        let wordCount = countWords(in: bodyContent)

        return Article(
            id: fileURL.lastPathComponent,
            title: title,
            author: author,
            sourceURL: sourceURL,
            publishedDate: publishedDate,
            content: bodyContent,
            filePath: fileURL,
            dateAdded: dateAdded,
            wordCount: wordCount
        )
    }

    private func parseFrontmatter(from content: String) -> (frontmatter: [String: Any], body: String) {
        let pattern = #"^---\s*\n([\s\S]*?)\n---\s*\n"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
              let frontmatterRange = Range(match.range(at: 1), in: content),
              let fullMatchRange = Range(match.range, in: content) else {
            return ([:], content)
        }

        let frontmatterString = String(content[frontmatterRange])
        let body = String(content[fullMatchRange.upperBound...])
        let frontmatter = parseYAML(frontmatterString)

        return (frontmatter, body)
    }

    private func parseYAML(_ yaml: String) -> [String: Any] {
        var result: [String: Any] = [:]
        var currentKey: String?
        var arrayValues: [String] = []
        var inArray = false

        let lines = yaml.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Array item
            if trimmed.hasPrefix("- ") {
                let value = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                let cleanValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                if currentKey != nil {
                    arrayValues.append(cleanValue)
                    inArray = true
                }
                continue
            }

            // Save previous array if we were building one
            if inArray, let key = currentKey {
                result[key] = arrayValues
                arrayValues = []
                inArray = false
            }

            // Key-value pair
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                currentKey = key

                if !value.isEmpty {
                    let cleanValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    result[key] = cleanValue
                }
            }
        }

        // Handle final array
        if inArray, let key = currentKey {
            result[key] = arrayValues
        }

        return result
    }

    private func extractTitle(from content: String, filename: String) -> String {
        // Try to find first H1 heading
        let pattern = #"^#\s+(.+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines),
           let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
           let titleRange = Range(match.range(at: 1), in: content) {
            return String(content[titleRange]).trimmingCharacters(in: .whitespaces)
        }

        // Fall back to filename
        return filename
    }

    private func extractAuthor(from frontmatter: [String: Any]) -> String? {
        if let authors = frontmatter["author"] as? [String], let first = authors.first {
            return first
        }
        if let author = frontmatter["author"] as? String {
            return author.isEmpty ? nil : author
        }
        return nil
    }

    private func extractSourceURL(from frontmatter: [String: Any]) -> URL? {
        guard let source = frontmatter["source"] as? String else { return nil }
        return URL(string: source)
    }

    private func extractPublishedDate(from frontmatter: [String: Any]) -> Date? {
        guard let published = frontmatter["published"] as? String else { return nil }

        let formatters = [
            "yyyy-MM-dd",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ssZ"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: published) {
                return date
            }
        }

        return nil
    }

    private func countWords(in content: String) -> Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
}

enum ArticleServiceError: Error {
    case folderNotFound
    case parsingError
}
