import SwiftUI

// Bear-inspired color theme
struct Theme {
    // Sidebar colors (dark charcoal)
    static let sidebarBackground = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let sidebarText = Color.white.opacity(0.9)
    static let sidebarSecondaryText = Color.white.opacity(0.5)
    static let sidebarIcon = Color.white.opacity(0.75)
    static let sidebarDivider = Color.white.opacity(0.1)

    // List panel colors (slightly lighter)
    static let listBackground = Color(red: 0.18, green: 0.18, blue: 0.19)
    static let listItemBackground = Color.clear
    static let listItemHover = Color.white.opacity(0.05)
    static let listItemSelected = Color(red: 0.85, green: 0.35, blue: 0.25) // Bear's orange-red
    static let listItemSelectedSubtle = Color.white.opacity(0.08) // Subtle selection background (Apple Notes style)
    static let listText = Color.white.opacity(0.95)
    static let listSecondaryText = Color.white.opacity(0.5)
    static let listTertiaryText = Color.white.opacity(0.35)

    // Content area colors
    static let contentBackground = Color(red: 0.98, green: 0.98, blue: 0.97)
    static let contentText = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let contentSecondaryText = Color(red: 0.45, green: 0.45, blue: 0.45)

    // Accent color
    static let accent = Color(red: 0.85, green: 0.35, blue: 0.25)
    static let accentSubtle = Color(red: 0.85, green: 0.35, blue: 0.25).opacity(0.15)

    // Tags
    static let tagBackground = Color.white.opacity(0.1)
    static let tagText = Color.white.opacity(0.7)

    // Search field
    static let searchBackground = Color.white.opacity(0.08)
    static let searchBorder = Color.white.opacity(0.1)
    static let searchPlaceholder = Color.white.opacity(0.6)

    // Progress
    static let progressTrack = Color.white.opacity(0.1)
    static let progressComplete = Color(red: 0.4, green: 0.75, blue: 0.45)
}

// Custom button style for sidebar
struct SidebarButtonStyle: ButtonStyle {
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Theme.listItemSelected : (configuration.isPressed ? Theme.listItemHover : Color.clear))
            )
            .foregroundColor(isSelected ? .white : Theme.sidebarText)
    }
}

// Custom text field style for search
struct SearchFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
    }
}
