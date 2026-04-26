import AppKit
import Foundation

struct Source: Identifiable, Codable, Equatable {
    let id: UUID
    var url: URL
    var title: String
    var rssURL: URL?
    var faviconData: Data?
    var readArticleIDs: Set<String>
    var knownArticleIDs: Set<String>

    init(id: UUID = UUID(), url: URL, title: String, rssURL: URL? = nil, faviconData: Data? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.rssURL = rssURL
        self.faviconData = faviconData
        self.readArticleIDs = []
        self.knownArticleIDs = []
    }

    var needsFaviconRefresh: Bool {
        guard let data = faviconData else { return true }
        return NSImage(data: data) == nil
    }

    var unreadCount: Int {
        knownArticleIDs.subtracting(readArticleIDs).count
    }

    mutating func markAllAsRead() {
        readArticleIDs.formUnion(knownArticleIDs)
    }

    mutating func updateKnownArticles(_ articleIDs: Set<String>) {
        knownArticleIDs = articleIDs
    }
}
