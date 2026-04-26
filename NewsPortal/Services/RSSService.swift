import Foundation
import FeedKit

struct RSSResult {
    let articleIDs: Set<String>
}

protocol RSSFetching {
    func fetchFeed(url: URL) async throws -> RSSResult
}

class RSSService: RSSFetching {
    func fetchFeed(url: URL) async throws -> RSSResult {
        try await withCheckedThrowingContinuation { continuation in
            let parser = FeedParser(URL: url)
            parser.parseAsync { result in
                switch result {
                case .success(let feed):
                    let ids = Self.extractArticleIDs(from: feed)
                    continuation.resume(returning: RSSResult(articleIDs: ids))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func extractArticleIDs(from feed: Feed) -> Set<String> {
        var ids: Set<String> = []

        switch feed {
        case .rss(let rssFeed):
            for item in rssFeed.items ?? [] {
                if let guid = item.guid?.value {
                    ids.insert(guid)
                } else if let link = item.link {
                    ids.insert(link)
                }
            }
        case .atom(let atomFeed):
            for entry in atomFeed.entries ?? [] {
                if let id = entry.id {
                    ids.insert(id)
                } else if let link = entry.links?.first?.attributes?.href {
                    ids.insert(link)
                }
            }
        case .json(let jsonFeed):
            for item in jsonFeed.items ?? [] {
                if let id = item.id {
                    ids.insert(id)
                } else if let url = item.url {
                    ids.insert(url)
                }
            }
        }

        return ids
    }
}
