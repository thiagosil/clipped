import SwiftUI

struct KeyboardShortcutsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.contentText)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.contentSecondaryText.opacity(0.5))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Navigation section
                    shortcutSection(title: "Navigation") {
                        shortcutRow(keys: ["Esc"], description: "Back to library")
                        shortcutRow(keys: ["⌘", "["], description: "Back to library")
                        shortcutRow(keys: ["n"], description: "Next unread article")
                        shortcutRow(keys: ["a"], description: "Archive article")
                    }

                    // Scrolling section
                    shortcutSection(title: "Scrolling") {
                        shortcutRow(keys: ["Space"], description: "Page down")
                        shortcutRow(keys: ["⇧", "Space"], description: "Page up")
                        shortcutRow(keys: ["↓"], orKeys: ["j"], description: "Scroll down")
                        shortcutRow(keys: ["↑"], orKeys: ["k"], description: "Scroll up")
                        shortcutRow(keys: ["g", "g"], description: "Go to top")
                        shortcutRow(keys: ["G"], description: "Go to bottom")
                    }

                    // View section
                    shortcutSection(title: "View") {
                        shortcutRow(keys: ["⌘", "B"], description: "Toggle sidebar")
                        shortcutRow(keys: ["⌘", "R"], description: "Refresh articles")
                        shortcutRow(keys: ["?"], description: "Show this help")
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 340, height: 420)
        .background(Theme.contentBackground)
    }

    @ViewBuilder
    private func shortcutSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.contentSecondaryText)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
    }

    @ViewBuilder
    private func shortcutRow(keys: [String], orKeys: [String]? = nil, description: String) -> some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                    KeyCapView(key: key)
                }

                if let orKeys = orKeys {
                    Text("or")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.contentSecondaryText.opacity(0.6))
                        .padding(.horizontal, 4)

                    ForEach(Array(orKeys.enumerated()), id: \.offset) { index, key in
                        KeyCapView(key: key)
                    }
                }
            }

            Spacer()

            Text(description)
                .font(.system(size: 13))
                .foregroundColor(Theme.contentSecondaryText)
        }
    }
}

struct KeyCapView: View {
    let key: String

    var body: some View {
        Text(key)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(Theme.contentText.opacity(0.8))
            .padding(.horizontal, key.count == 1 ? 8 : 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 0.5, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Theme.contentSecondaryText.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    KeyboardShortcutsView()
}
