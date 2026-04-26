import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var store = SourceStore()
    @StateObject private var webNavigator = WebViewNavigator()
    @State private var selectedSourceID: UUID?

    private let rssService: RSSFetching = RSSService()
    private let pageFetcher: PageFetching = PageFetcher()

    var body: some View {
        NavigationSplitView {
            SourceListView(store: store, selectedSourceID: $selectedSourceID)
                .frame(minWidth: 220)
        } detail: {
            if let id = selectedSourceID,
               let source = store.sources.first(where: { $0.id == id }) {
                WebView(url: source.url, navigator: webNavigator)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .toolbar {
                        ToolbarItemGroup(placement: .primaryAction) {
                            Button(action: { webNavigator.goBack() }) {
                                Label("Back", systemImage: "chevron.left")
                            }
                            .disabled(!webNavigator.canGoBack)
                            .keyboardShortcut("[", modifiers: .command)

                            Button(action: { webNavigator.goForward() }) {
                                Label("Forward", systemImage: "chevron.right")
                            }
                            .disabled(!webNavigator.canGoForward)
                            .keyboardShortcut("]", modifiers: .command)
                        }
                    }
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
                Task { await fetchFaviconIfNeeded(id: id) }
            }
        }
        .task {
            await refreshAllFeeds()
            await refreshMissingFavicons()
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

    private func refreshMissingFavicons() async {
        for source in store.sources where source.needsFaviconRefresh {
            await fetchFaviconIfNeeded(id: source.id)
        }
    }

    private func fetchFaviconIfNeeded(id: UUID) async {
        guard let source = store.sources.first(where: { $0.id == id }),
              source.needsFaviconRefresh else { return }
        do {
            let metadata = try await pageFetcher.fetch(url: source.url)
            if let data = await pageFetcher.fetchFavicon(for: source.url, faviconURL: metadata.faviconURL) {
                store.updateFavicon(id: id, data: data)
            }
        } catch {
            print("Favicon fetch failed for \(source.title): \(error)")
        }
    }
}
