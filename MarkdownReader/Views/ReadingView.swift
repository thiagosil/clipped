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
                    VStack(alignment: .leading, spacing: 20) {
                        // Top anchor for scroll navigation
                        Color.clear
                            .frame(height: 1)
                            .id("top")

                        // Header
                        articleHeader
                            .padding(.bottom, 16)

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
                    .padding(.horizontal, max(48, (geometry.size.width - settings.contentWidth) / 2))
                    .padding(.top, 48)
                    .padding(.bottom, 80)
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
        .background(Theme.contentBackground)
        .overlay(alignment: .topTrailing) {
            toolbarButtons
        }
        .overlay(alignment: .bottom) {
            progressBar
        }
    }

    // MARK: - Article Header

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(article.title)
                .font(.system(size: settings.fontSize + 12, weight: .bold, design: settings.fontDesign))
                .foregroundColor(Theme.contentText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let author = article.author {
                    Text(author)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.contentSecondaryText)
                }

                if article.author != nil && article.sourceDomain != nil {
                    Text("·")
                        .foregroundColor(Theme.contentSecondaryText.opacity(0.5))
                }

                if let domain = article.sourceDomain {
                    Text(domain)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.contentSecondaryText.opacity(0.8))
                }

                Text("·")
                    .foregroundColor(Theme.contentSecondaryText.opacity(0.5))

                Text("\(article.estimatedReadingTime) min read")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.contentSecondaryText.opacity(0.8))
            }

            // Tags
            if !article.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(article.tags.prefix(8), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.accent.opacity(0.1))
                                .foregroundColor(Theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, 4)
            }

            // Separator
            Rectangle()
                .fill(Theme.contentSecondaryText.opacity(0.1))
                .frame(height: 1)
                .padding(.top, 8)
        }
    }

    // MARK: - Toolbar

    private var toolbarButtons: some View {
        HStack(spacing: 8) {
            // Settings button
            Button(action: { showSettings.toggle() }) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.contentSecondaryText)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Theme.contentBackground)
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings) {
                ReadingSettingsView(settings: settings)
                    .padding()
                    .frame(width: 260)
            }

            // Open in browser
            if let url = article.sourceURL {
                Button(action: {
                    NSWorkspace.shared.open(url)
                }) {
                    Image(systemName: "safari")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.contentSecondaryText)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Theme.contentBackground)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
                .help("Open original article")
            }
        }
        .padding(16)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [Theme.contentBackground.opacity(0), Theme.contentBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)

            // Progress bar container
            HStack {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.contentSecondaryText.opacity(0.1))

                        // Progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(scrollPosition >= 100 ? Theme.progressComplete : Theme.accent)
                            .frame(width: geo.size.width * CGFloat(scrollPosition / 100))
                    }
                }
                .frame(height: 3)

                Text("\(Int(scrollPosition))%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.contentSecondaryText.opacity(0.6))
                    .frame(width: 36, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(Theme.contentBackground)
        }
    }

    // MARK: - Key Handling

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
        let pageHeight = viewHeight - 50
        let currentY = scrollView.contentView.bounds.origin.y
        let newY = up ? currentY - pageHeight : currentY + pageHeight
        let clampedY = max(0, min(newY, scrollView.documentView!.bounds.height - viewHeight))

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
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
        let percentage = min(100, max(0, -offset / (height * 2) * 100))
        scrollPosition = percentage
        appState.saveProgress(for: article, percentage: percentage, scrollPosition: offset)
    }

    private func restoreScrollPosition(scrollProxy: ScrollViewProxy, viewHeight: CGFloat) {
        if let progress = appState.getProgress(for: article) {
            scrollPosition = progress.percentage

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

// MARK: - Helpers

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

// MARK: - Markdown Content View

struct MarkdownContentView: View {
    let content: String
    let fontSize: CGFloat
    let fontDesign: Font.Design
    let lineSpacing: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing + 4) {
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
                    elements.append(.codeBlock(language: codeBlockLanguage, code: codeBlockContent))
                    codeBlockContent = ""
                    codeBlockLanguage = nil
                    inCodeBlock = false
                } else {
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

            // Regular text
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
                .font(.system(size: fontSize + CGFloat(20 - level * 3), weight: .semibold, design: fontDesign))
                .foregroundColor(Theme.contentText)
                .padding(.top, CGFloat(20 - level * 2))

        case .paragraph(let text):
            Text(processInlineMarkdown(text))
                .font(.system(size: fontSize, design: fontDesign))
                .foregroundColor(Theme.contentText.opacity(0.9))
                .lineSpacing(lineSpacing * 0.4)

        case .listItem(let text):
            HStack(alignment: .top, spacing: 12) {
                Text("•")
                    .foregroundColor(Theme.accent)
                Text(processInlineMarkdown(text))
                    .font(.system(size: fontSize, design: fontDesign))
                    .foregroundColor(Theme.contentText.opacity(0.9))
            }
            .padding(.leading, 4)

        case .blockquote(let text):
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent.opacity(0.6))
                    .frame(width: 3)
                Text(processInlineMarkdown(text))
                    .font(.system(size: fontSize, design: fontDesign))
                    .italic()
                    .foregroundColor(Theme.contentSecondaryText)
            }
            .padding(.vertical, 8)
            .padding(.leading, 4)

        case .codeBlock(let language, let code):
            VStack(alignment: .leading, spacing: 0) {
                if let lang = language {
                    Text(lang.uppercased())
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.contentSecondaryText.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(size: fontSize - 2, design: .monospaced))
                        .foregroundColor(Theme.contentText.opacity(0.85))
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                        .padding(.vertical, language == nil ? 16 : 8)
                        .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.contentSecondaryText.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.contentSecondaryText.opacity(0.08), lineWidth: 1)
            )

        case .image(let alt, let url):
            if let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.contentSecondaryText))
                                .scaleEffect(0.6)
                            Text("Loading...")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.contentSecondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Theme.contentSecondaryText.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    case .success(let image):
                        VStack(spacing: 8) {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            if !alt.isEmpty {
                                Text(alt)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.contentSecondaryText)
                            }
                        }

                    case .failure:
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Theme.contentSecondaryText.opacity(0.4))
                            Text(alt.isEmpty ? "Failed to load" : alt)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.contentSecondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Theme.contentSecondaryText.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    @unknown default:
                        EmptyView()
                    }
                }
            }

        case .horizontalRule:
            Rectangle()
                .fill(Theme.contentSecondaryText.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 24)
        }
    }

    private func processInlineMarkdown(_ text: String) -> AttributedString {
        if let attributed = try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }

        var result = text
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
