import SwiftUI

class ReadingSettings: ObservableObject {
    @AppStorage("fontSize") var fontSize: Double = 18
    @AppStorage("lineSpacing") var lineSpacing: Double = 8
    @AppStorage("contentWidth") var contentWidth: Double = 680
    @AppStorage("fontDesignRaw") private var fontDesignRaw: String = "default"

    var fontDesign: Font.Design {
        get {
            switch fontDesignRaw {
            case "serif": return .serif
            case "monospaced": return .monospaced
            default: return .default
            }
        }
        set {
            switch newValue {
            case .serif: fontDesignRaw = "serif"
            case .monospaced: fontDesignRaw = "monospaced"
            default: fontDesignRaw = "default"
            }
            objectWillChange.send()
        }
    }
}
