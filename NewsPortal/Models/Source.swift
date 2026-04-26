import Foundation

struct Source: Identifiable, Codable, Equatable {
    let id: UUID
    var url: URL
    var title: String
    var rssURL: URL?
    var readArticleIDs: Set<String>
    var knownArticleIDs: Set<String>

    init(id: UUID = UUID(), url: URL, title: String, rssURL: URL? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.rssURL = rssURL
        self.readArticleIDs = []
        self.knownArticleIDs = []
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
