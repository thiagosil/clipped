import SwiftUI
import AppKit

struct ReadingView: View {
    let article: Article
    @EnvironmentObject var appState: AppState
    @StateObject private var settings = ReadingSettings()

    @State private var scrollPosition: Double = 0
    @State private var showSettings = false
    @State private var lastKeyPress: (key: Character, time: Date)?
    @State private var nsScrollView: NSScrollView?

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Top anchor for scroll navigation
                        Color.clear
                            .frame(height: 1)
                            .id("top")

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

                        // Bottom anchor for scroll navigation
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, max(40, (geometry.size.width - settings.contentWidth) / 2))
                    .padding(.vertical, 40)
                    .background(GeometryReader { contentGeometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: contentGeometry.frame(in: .named("scroll")).minY
                        )
                    })
                    .background(NSScrollViewFinder(scrollView: $nsScrollView))
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    updateScrollPosition(offset: offset, height: geometry.size.height)
                }
                .onAppear {
                    restoreScrollPosition(scrollProxy: scrollProxy, viewHeight: geometry.size.height)
                }
                .onKeyPress { keyPress in
                    handleKeyPress(keyPress, scrollProxy: scrollProxy, viewHeight: geometry.size.height)
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

    private func handleKeyPress(_ keyPress: KeyPress, scrollProxy: ScrollViewProxy, viewHeight: CGFloat) -> KeyPress.Result {
        let key = keyPress.characters.first

        switch keyPress.key {
        case .escape:
            appState.selectedArticle = nil
            return .handled

        case .space:
            if keyPress.modifiers.contains(.shift) {
                scrollPage(up: true, viewHeight: viewHeight)
            } else {
                scrollPage(up: false, viewHeight: viewHeight)
            }
            return .handled

        case .downArrow:
            scrollIncrement(up: false)
            return .handled

        case .upArrow:
            scrollIncrement(up: true)
            return .handled

        default:
            break
        }

        // Letter keys
        if let key = key {
            switch key {
            case "j":
                scrollIncrement(up: false)
                return .handled

            case "k":
                scrollIncrement(up: true)
                return .handled

            case "g":
                // Check for double-tap
                if let last = lastKeyPress, last.key == "g",
                   Date().timeIntervalSince(last.time) < 0.5 {
                    withAnimation {
                        scrollProxy.scrollTo("top", anchor: .top)
                    }
                    lastKeyPress = nil
                } else {
                    lastKeyPress = ("g", Date())
                }
                return .handled

            case "G":
                withAnimation {
                    scrollProxy.scrollTo("bottom", anchor: .bottom)
                }
                return .handled

            default:
                break
            }
        }

        return .ignored
    }

    private func scrollPage(up: Bool, viewHeight: CGFloat) {
        guard let scrollView = nsScrollView else { return }
        let pageHeight = viewHeight - 50 // Leave some overlap
        let currentY = scrollView.contentView.bounds.origin.y
        let newY = up ? currentY - pageHeight : currentY + pageHeight
        let clampedY = max(0, min(newY, scrollView.documentView!.bounds.height - viewHeight))

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: clampedY))
        }
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func scrollIncrement(up: Bool) {
        guard let scrollView = nsScrollView else { return }
        let increment: CGFloat = 60
        let currentY = scrollView.contentView.bounds.origin.y
        let newY = up ? currentY - increment : currentY + increment
        let maxY = scrollView.documentView!.bounds.height - scrollView.contentView.bounds.height
        let clampedY = max(0, min(newY, maxY))

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: clampedY))
        }
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func updateScrollPosition(offset: CGFloat, height: CGFloat) {
        // Calculate percentage based on scroll offset
        let percentage = min(100, max(0, -offset / (height * 2) * 100))
        scrollPosition = percentage

        // Save progress periodically
        appState.saveProgress(for: article, percentage: percentage, scrollPosition: offset)
    }

    private func restoreScrollPosition(scrollProxy: ScrollViewProxy, viewHeight: CGFloat) {
        if let progress = appState.getProgress(for: article) {
            scrollPosition = progress.percentage

            // Use a slight delay to ensure the scroll view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let scrollView = nsScrollView {
                    let targetY = -progress.scrollPosition
                    let maxY = scrollView.documentView!.bounds.height - scrollView.contentView.bounds.height
                    let clampedY = max(0, min(targetY, maxY))
                    scrollView.contentView.setBoundsOrigin(NSPoint(x: 0, y: clampedY))
                    scrollView.reflectScrolledClipView(scrollView.contentView)
                }
            }
        }
    }
}

// Helper to find the underlying NSScrollView
struct NSScrollViewFinder: NSViewRepresentable {
    @Binding var scrollView: NSScrollView?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.scrollView = findScrollView(in: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if self.scrollView == nil {
                self.scrollView = findScrollView(in: nsView)
            }
        }
    }

    private func findScrollView(in view: NSView) -> NSScrollView? {
        var current: NSView? = view
        while let view = current {
            if let scrollView = view as? NSScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
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
            ForEach(Array(parseContent().enumerated()), id: \.offset) { index, element in
                renderElement(element)
                    .id("element-\(index)")
            }
        }
    }

    private func parseContent() -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = content.components(separatedBy: "\n")
        var currentParagraph = ""
        var inCodeBlock = false
        var codeBlockLanguage: String?
        var codeBlockContent = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code block handling
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    elements.append(.codeBlock(language: codeBlockLanguage, code: codeBlockContent))
                    codeBlockContent = ""
                    codeBlockLanguage = nil
                    inCodeBlock = false
                } else {
                    // Start code block
                    if !currentParagraph.isEmpty {
                        elements.append(.paragraph(currentParagraph))
                        currentParagraph = ""
                    }
                    let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeBlockLanguage = lang.isEmpty ? nil : lang
                    inCodeBlock = true
                }
                continue
            }

            if inCodeBlock {
                if !codeBlockContent.isEmpty {
                    codeBlockContent += "\n"
                }
                codeBlockContent += line
                continue
            }

            // Horizontal rules
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                elements.append(.horizontalRule)
                continue
            }

            // Images
            if let imageMatch = trimmed.range(of: #"!\[([^\]]*)\]\(([^\)]+)\)"#, options: .regularExpression) {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                let imageText = String(trimmed[imageMatch])
                if let altMatch = imageText.range(of: #"\[([^\]]*)\]"#, options: .regularExpression),
                   let urlMatch = imageText.range(of: #"\(([^\)]+)\)"#, options: .regularExpression) {
                    let alt = String(imageText[altMatch]).dropFirst().dropLast()
                    let url = String(imageText[urlMatch]).dropFirst().dropLast()
                    elements.append(.image(alt: String(alt), url: String(url)))
                }
                continue
            }

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

        case .codeBlock(let language, let code):
            VStack(alignment: .leading, spacing: 4) {
                if let lang = language {
                    Text(lang)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(code)
                        .font(.system(size: fontSize - 2, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )

        case .image(let alt, let url):
            if let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        HStack {
                            ProgressView()
                                .scaleEffect(0.5)
                            Text("Loading image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    case .success(let image):
                        VStack(spacing: 4) {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(8)
                            if !alt.isEmpty {
                                Text(alt)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    case .failure:
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text(alt.isEmpty ? "Failed to load image" : alt)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

        case .horizontalRule:
            Divider()
                .padding(.vertical, 16)
        }
    }

    private func processInlineMarkdown(_ text: String) -> AttributedString {
        // Try using native markdown parsing first
        if let attributed = try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }

        // Fallback to manual processing
        var result = text

        // Remove markdown links, keep text
        result = result.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^\)]+\)"#,
            with: "$1",
            options: .regularExpression
        )

        return AttributedString(result)
    }
}

enum MarkdownElement {
    case header(level: Int, text: String)
    case paragraph(String)
    case listItem(String)
    case blockquote(String)
    case codeBlock(language: String?, code: String)
    case image(alt: String, url: String)
    case horizontalRule
}
