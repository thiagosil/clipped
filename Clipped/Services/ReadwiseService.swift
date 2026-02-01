import Foundation
import Demark

enum ReadwiseError: Error, LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case rateLimited(retryAfter: Int)
    case serverError(statusCode: Int)
    case noDocumentsFound
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimited(let seconds):
            return "Rate limited. Retry after \(seconds) seconds"
        case .serverError(let code):
            return "Server error (status \(code))"
        case .noDocumentsFound:
            return "No documents found"
        case .conversionFailed:
            return "Failed to convert HTML to Markdown"
        }
    }
}

actor ReadwiseService {
    private let baseURL = "https://readwise.io"
    private let decoder = JSONDecoder()

    func validateAPIKey(_ apiKey: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/v2/auth/")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReadwiseError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 204:
                return true
            case 401:
                throw ReadwiseError.invalidAPIKey
            case 429:
                let retryAfter = Int(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
                throw ReadwiseError.rateLimited(retryAfter: retryAfter)
            default:
                throw ReadwiseError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch let error as ReadwiseError {
            throw error
        } catch {
            throw ReadwiseError.networkError(error)
        }
    }

    func fetchDocuments(
        apiKey: String,
        pageCursor: String? = nil,
        category: String = "article",
        location: String? = nil,
        updatedAfter: Date? = nil,
        withHtmlContent: Bool = true
    ) async throws -> ReadwiseListResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/api/v3/list/")!
        var queryItems = [URLQueryItem(name: "category", value: category)]

        if let cursor = pageCursor {
            queryItems.append(URLQueryItem(name: "pageCursor", value: cursor))
        }

        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }

        if let updatedAfter = updatedAfter {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            queryItems.append(URLQueryItem(name: "updatedAfter", value: formatter.string(from: updatedAfter)))
        }

        if withHtmlContent {
            queryItems.append(URLQueryItem(name: "withHtmlContent", value: "true"))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ReadwiseError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReadwiseError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                // Debug: print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw API response (first 2000 chars): \(String(jsonString.prefix(2000)))")
                }
                return try decoder.decode(ReadwiseListResponse.self, from: data)
            } catch {
                print("Decoding error details: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed JSON (first 2000 chars): \(String(jsonString.prefix(2000)))")
                }
                throw ReadwiseError.invalidResponse
            }
        case 401:
            throw ReadwiseError.invalidAPIKey
        case 429:
            let retryAfter = Int(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw ReadwiseError.rateLimited(retryAfter: retryAfter)
        default:
            throw ReadwiseError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    func fetchAllDocuments(
        apiKey: String,
        category: String = "article",
        location: String? = nil,
        updatedAfter: Date? = nil,
        onProgress: @escaping @Sendable (ReadwiseImportProgress) -> Void
    ) async throws -> [ReadwiseDocument] {
        var allDocuments: [ReadwiseDocument] = []
        var cursor: String? = nil
        var currentPage = 1
        var totalCount: Int? = nil

        repeat {
            do {
                let response = try await fetchDocuments(
                    apiKey: apiKey,
                    pageCursor: cursor,
                    category: category,
                    location: location,
                    updatedAfter: updatedAfter
                )

                if totalCount == nil {
                    totalCount = response.count
                }

                allDocuments.append(contentsOf: response.results)
                cursor = response.nextPageCursor

                onProgress(ReadwiseImportProgress(
                    totalCount: totalCount,
                    fetchedCount: allDocuments.count,
                    currentPage: currentPage,
                    status: .fetching
                ))

                currentPage += 1

            } catch ReadwiseError.rateLimited(let retryAfter) {
                onProgress(ReadwiseImportProgress(
                    totalCount: totalCount,
                    fetchedCount: allDocuments.count,
                    currentPage: currentPage,
                    status: .rateLimited(retryAfter: retryAfter)
                ))

                try await Task.sleep(nanoseconds: UInt64(retryAfter) * 1_000_000_000)
            }
        } while cursor != nil

        onProgress(ReadwiseImportProgress(
            totalCount: totalCount,
            fetchedCount: allDocuments.count,
            currentPage: currentPage,
            status: .completed
        ))

        return allDocuments
    }

    @MainActor
    func convertToMarkdown(document: ReadwiseDocument) async -> String? {
        guard let html = document.htmlContent ?? document.html ?? document.content else {
            print("No HTML content for document: \(document.title ?? document.id)")
            return nil
        }

        // Use Demark to convert HTML to Markdown
        let demark = Demark()
        let markdown: String
        do {
            markdown = try await demark.convertToMarkdown(html)
        } catch {
            print("Demark conversion failed: \(error)")
            // Fall back to basic HTML stripping
            markdown = stripHTML(html)
        }

        // Build frontmatter
        var frontmatter = "---\n"

        if let title = document.title {
            frontmatter += "title: \"\(title.replacingOccurrences(of: "\"", with: "\\\""))\"\n"
        }

        if let author = document.author {
            frontmatter += "author: \"\(author.replacingOccurrences(of: "\"", with: "\\\""))\"\n"
        }

        if let url = document.sourceURL ?? document.url {
            frontmatter += "source: \(url)\n"
        }

        if let publishedDate = document.publishedDate {
            frontmatter += "published: \(publishedDate)\n"
        }

        let tagNames = document.tagNames
        if !tagNames.isEmpty {
            let tagList = tagNames.joined(separator: ", ")
            frontmatter += "tags: [\(tagList)]\n"
        }

        frontmatter += "---\n\n"

        return frontmatter + markdown
    }

    nonisolated private func stripHTML(_ html: String) -> String {
        // Basic HTML to text fallback
        var result = html
        // Remove script and style tags with content
        result = result.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        // Convert common tags
        result = result.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
        result = result.replacingOccurrences(of: "</p>", with: "\n\n")
        result = result.replacingOccurrences(of: "</div>", with: "\n")
        result = result.replacingOccurrences(of: "</h[1-6]>", with: "\n\n", options: .regularExpression)
        // Remove remaining tags
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Decode common entities
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        // Clean up whitespace
        result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated func sanitizeFilename(_ title: String) -> String {
        // Remove or replace characters that are invalid in filenames
        var sanitized = title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "\"", with: "'")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "|", with: "-")

        // Trim whitespace and limit length
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)

        // Limit to reasonable filename length
        if sanitized.count > 200 {
            sanitized = String(sanitized.prefix(200))
        }

        // Ensure we have something
        if sanitized.isEmpty {
            sanitized = "Untitled"
        }

        return sanitized
    }
}
