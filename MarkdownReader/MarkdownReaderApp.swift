import SwiftUI

@main
struct MarkdownReaderApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandGroup(after: .sidebar) {
                Button("Back to Library") {
                    appState.selectedArticle = nil
                }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(appState.selectedArticle == nil)

                Divider()

                Button("Refresh Articles") {
                    Task {
                        await appState.loadArticles()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
