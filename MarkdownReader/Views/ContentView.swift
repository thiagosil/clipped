import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            LibraryView()
        } detail: {
            if let article = appState.selectedArticle {
                ReadingView(article: article)
            } else {
                Text("Select an article to read")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await appState.loadArticles()
        }
    }
}
