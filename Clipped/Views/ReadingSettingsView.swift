import SwiftUI

struct ReadingSettingsView: View {
    @ObservedObject var settings: ReadingSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Settings")
                .font(.headline)

            // Font size
            VStack(alignment: .leading, spacing: 4) {
                Text("Font Size")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Text("A")
                        .font(.system(size: 12))
                    Slider(value: $settings.fontSize, in: 14...28, step: 1)
                    Text("A")
                        .font(.system(size: 20))
                }
            }

            // Font design
            VStack(alignment: .leading, spacing: 4) {
                Text("Font")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("Font", selection: Binding(
                    get: { settings.fontDesign },
                    set: { settings.fontDesign = $0 }
                )) {
                    Text("Sans Serif").tag(Font.Design.default)
                    Text("Serif").tag(Font.Design.serif)
                    Text("Monospace").tag(Font.Design.monospaced)
                }
                .pickerStyle(.segmented)
            }

            // Line spacing
            VStack(alignment: .leading, spacing: 4) {
                Text("Line Spacing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 12))
                    Slider(value: $settings.lineSpacing, in: 4...16, step: 1)
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 16))
                }
            }

            // Content width
            VStack(alignment: .leading, spacing: 4) {
                Text("Content Width")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 12))
                    Slider(value: $settings.contentWidth, in: 500...900, step: 20)
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 16))
                }
            }
        }
    }
}
