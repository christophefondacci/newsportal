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
    var quizPages: [QuizPage]

    init(id: UUID = UUID(), url: URL, title: String, rssURL: URL? = nil, faviconData: Data? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.rssURL = rssURL
        self.faviconData = faviconData
        self.readArticleIDs = []
        self.knownArticleIDs = []
        self.quizPages = []
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        title = try container.decode(String.self, forKey: .title)
        rssURL = try container.decodeIfPresent(URL.self, forKey: .rssURL)
        faviconData = try container.decodeIfPresent(Data.self, forKey: .faviconData)
        readArticleIDs = try container.decodeIfPresent(Set<String>.self, forKey: .readArticleIDs) ?? []
        knownArticleIDs = try container.decodeIfPresent(Set<String>.self, forKey: .knownArticleIDs) ?? []
        quizPages = try container.decodeIfPresent([QuizPage].self, forKey: .quizPages) ?? []
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
