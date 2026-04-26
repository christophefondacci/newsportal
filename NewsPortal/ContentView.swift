import SwiftUI

struct ContentView: View {
    @StateObject private var store = SourceStore()
    @State private var selectedSourceID: UUID?

    private let rssService: RSSFetching = RSSService()

    var body: some View {
        NavigationSplitView {
            SourceListView(store: store, selectedSourceID: $selectedSourceID)
                .frame(minWidth: 220)
        } detail: {
            if let id = selectedSourceID,
               let source = store.sources.first(where: { $0.id == id }) {
                WebView(url: source.url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Select a source to browse")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: selectedSourceID) { _, newValue in
            if let id = newValue {
                store.markAsRead(id: id)
            }
        }
        .task {
            await refreshAllFeeds()
        }
    }

    private func refreshAllFeeds() async {
        for source in store.sources where source.rssURL != nil {
            guard let rssURL = source.rssURL else { continue }
            do {
                let result = try await rssService.fetchFeed(url: rssURL)
                store.updateKnownArticles(id: source.id, articleIDs: result.articleIDs)
            } catch {
                print("RSS fetch failed for \(source.title): \(error)")
            }
        }
    }
}
