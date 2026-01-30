import SwiftUI

struct ReadingView: View {
    let article: Article
    @EnvironmentObject var appState: AppState
    @StateObject private var settings = ReadingSettings()

    @State private var scrollPosition: Double = 0
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        VStack(alignment: .center, spacing: 8) {
                            Text(article.title)
                                .font(.system(size: settings.fontSize + 8, weight: .bold, design: settings.fontDesign))
                                .multilineTextAlignment(.center)

                            HStack(spacing: 8) {
                                if let author = article.author {
                                    Text(author)
                                }
                                if article.author != nil && article.sourceDomain != nil {
                                    Text("·")
                                }
                                if let domain = article.sourceDomain {
                                    Text(domain)
                                }
                                Text("·")
                                Text("\(article.estimatedReadingTime) min read")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 24)

                        // Content
                        MarkdownContentView(
                            content: article.content,
                            fontSize: settings.fontSize,
                            fontDesign: settings.fontDesign,
                            lineSpacing: settings.lineSpacing
                        )
                    }
                    .padding(.horizontal, max(40, (geometry.size.width - settings.contentWidth) / 2))
                    .padding(.vertical, 40)
                    .background(GeometryReader { contentGeometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: contentGeometry.frame(in: .named("scroll")).minY
                        )
                    })
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    updateScrollPosition(offset: offset, height: geometry.size.height)
                }
                .onAppear {
                    restoreScrollPosition()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "textformat.size")
                }
                .popover(isPresented: $showSettings) {
                    ReadingSettingsView(settings: settings)
                        .padding()
                        .frame(width: 250)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                if let url = article.sourceURL {
                    Button(action: {
                        NSWorkspace.shared.open(url)
                    }) {
                        Image(systemName: "safari")
                    }
                    .help("Open original article")
                }
            }
        }
        .overlay(alignment: .bottom) {
            // Progress bar
            ProgressView(value: scrollPosition / 100)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    private func updateScrollPosition(offset: CGFloat, height: CGFloat) {
        // Calculate percentage based on scroll offset
        let percentage = min(100, max(0, -offset / (height * 2) * 100))
        scrollPosition = percentage

        // Save progress periodically
        appState.saveProgress(for: article, percentage: percentage, scrollPosition: offset)
    }

    private func restoreScrollPosition() {
        if let progress = appState.getProgress(for: article) {
            scrollPosition = progress.percentage
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MarkdownContentView: View {
    let content: String
    let fontSize: CGFloat
    let fontDesign: Font.Design
    let lineSpacing: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(Array(parseContent().enumerated()), id: \.offset) { _, element in
                renderElement(element)
            }
        }
    }

    private func parseContent() -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = content.components(separatedBy: "\n")
        var currentParagraph = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                continue
            }

            // Headers
            if let headerMatch = trimmed.range(of: #"^(#{1,6})\s+(.+)$"#, options: .regularExpression) {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                let headerText = String(trimmed[headerMatch])
                let level = headerText.prefix(while: { $0 == "#" }).count
                let text = String(headerText.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                elements.append(.header(level: level, text: text))
                continue
            }

            // Code blocks
            if trimmed.hasPrefix("```") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                continue
            }

            // List items
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                let listText = trimmed.replacingOccurrences(of: #"^[-*]\s+"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"^\d+\.\s+"#, with: "", options: .regularExpression)
                elements.append(.listItem(listText))
                continue
            }

            // Blockquotes
            if trimmed.hasPrefix("> ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                let quoteText = String(trimmed.dropFirst(2))
                elements.append(.blockquote(quoteText))
                continue
            }

            // Regular text - accumulate into paragraph
            if currentParagraph.isEmpty {
                currentParagraph = trimmed
            } else {
                currentParagraph += " " + trimmed
            }
        }

        if !currentParagraph.isEmpty {
            elements.append(.paragraph(currentParagraph))
        }

        return elements
    }

    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element {
        case .header(let level, let text):
            Text(processInlineMarkdown(text))
                .font(.system(size: fontSize + CGFloat(24 - level * 3), weight: .semibold, design: fontDesign))
                .padding(.top, CGFloat(16 - level * 2))

        case .paragraph(let text):
            Text(processInlineMarkdown(text))
                .font(.system(size: fontSize, design: fontDesign))
                .lineSpacing(lineSpacing * 0.3)

        case .listItem(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                Text(processInlineMarkdown(text))
                    .font(.system(size: fontSize, design: fontDesign))
            }
            .padding(.leading, 16)

        case .blockquote(let text):
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 3)
                Text(processInlineMarkdown(text))
                    .font(.system(size: fontSize, design: fontDesign))
                    .italic()
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func processInlineMarkdown(_ text: String) -> AttributedString {
        var result = text

        // Remove markdown links, keep text
        result = result.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^\)]+\)"#,
            with: "$1",
            options: .regularExpression
        )

        // Convert to AttributedString (basic - could be enhanced)
        let attributed = AttributedString(result)
        return attributed
    }
}

enum MarkdownElement {
    case header(level: Int, text: String)
    case paragraph(String)
    case listItem(String)
    case blockquote(String)
}
