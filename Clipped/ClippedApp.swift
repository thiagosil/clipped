import SwiftUI
import AppKit

@main
struct MarkdownReaderApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .sheet(isPresented: $appState.showKeyboardShortcuts) {
                    KeyboardShortcutsView()
                }
                .background(
                    KeyboardShortcutHandler(showShortcuts: $appState.showKeyboardShortcuts)
                )
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Choose Folder...") {
                    appState.selectFolder()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .sidebar) {
                Button(appState.sidebarVisible ? "Hide Sidebar" : "Show Sidebar") {
                    withAnimation(.easeOut(duration: 0.15)) {
                        appState.sidebarVisible.toggle()
                    }
                }
                .keyboardShortcut("b", modifiers: .command)

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

            CommandGroup(replacing: .help) {
                Button("Keyboard Shortcuts") {
                    appState.showKeyboardShortcuts = true
                }
                .keyboardShortcut("/", modifiers: .command)
            }
        }
    }
}

// MARK: - Global Keyboard Shortcut Handler

struct KeyboardShortcutHandler: NSViewRepresentable {
    @Binding var showShortcuts: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.setupMonitor(showShortcuts: $showShortcuts)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    class Coordinator {
        var monitor: Any?

        func setupMonitor(showShortcuts: Binding<Bool>) {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Check for ? key (Shift + /)
                if event.characters == "?" {
                    DispatchQueue.main.async {
                        showShortcuts.wrappedValue = true
                    }
                    return nil // Consume the event
                }
                return event
            }
        }

        func removeMonitor() {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            removeMonitor()
        }
    }
}
