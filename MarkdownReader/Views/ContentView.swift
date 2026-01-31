import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var sidebarWidth: CGFloat = 340

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with article list - always in hierarchy, width animates to 0
            VStack(spacing: 0) {
                // Window drag area (for traffic lights)
                WindowDragArea()
                    .frame(height: 28)
                    .background(Theme.listBackground)

                LibraryView()
            }
            .frame(width: appState.sidebarVisible ? sidebarWidth : 0)
            .clipped()

            // Resize handle
            if appState.sidebarVisible {
                resizeHandle
            }

            // Content area
            ZStack {
                Theme.contentBackground
                    .ignoresSafeArea()

                if let article = appState.selectedArticle {
                    ReadingView(article: article)
                } else {
                    EmptyContentView()
                }
            }
        }
        .task {
            await appState.loadArticles()
        }
        .ignoresSafeArea()
    }

    private var resizeHandle: some View {
        Rectangle()
            .fill(Color.black.opacity(0.3))
            .frame(width: 1)
            .contentShape(Rectangle().inset(by: -3))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newWidth = sidebarWidth + value.translation.width
                        sidebarWidth = max(280, min(500, newWidth))
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Empty State View

struct EmptyContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Decorative illustration
            ZStack {
                Circle()
                    .fill(Theme.contentSecondaryText.opacity(0.05))
                    .frame(width: 160, height: 160)

                Image(systemName: "book.pages")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundColor(Theme.contentSecondaryText.opacity(0.4))
            }

            VStack(spacing: 8) {
                Text("Select an article")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.contentSecondaryText)

                Text("Choose an article from the sidebar to start reading")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.contentSecondaryText.opacity(0.7))
            }

            // Keyboard shortcuts hint
            VStack(spacing: 12) {
                HStack(spacing: 24) {
                    shortcutHint(keys: ["↑", "↓"], description: "Navigate")
                    shortcutHint(keys: ["Space"], description: "Page down")
                    shortcutHint(keys: ["?"], description: "All shortcuts")
                }
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func shortcutHint(keys: [String], description: String) -> some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.contentSecondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.contentSecondaryText.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Theme.contentSecondaryText.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(Theme.contentSecondaryText.opacity(0.6))
        }
    }
}

// MARK: - Window Drag Area

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = WindowDragView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class WindowDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
