import XCTest
import FeedKit
@testable import NewsPortal

final class RSSServiceTests: XCTestCase {

    func testExtractArticleIDsFromRSSWithGuids() {
        let feed = RSSFeed()
        let item1 = RSSFeedItem()
        item1.guid = RSSFeedItemGUID()
        item1.guid?.value = "guid-1"
        let item2 = RSSFeedItem()
        item2.guid = RSSFeedItemGUID()
        item2.guid?.value = "guid-2"
        feed.items = [item1, item2]

        let ids = RSSService.extractArticleIDs(from: Feed.rss(feed))
        XCTAssertEqual(ids, ["guid-1", "guid-2"])
    }

    func testExtractArticleIDsFromRSSFallsBackToLink() {
        let feed = RSSFeed()
        let item = RSSFeedItem()
        item.link = "https://example.com/article"
        feed.items = [item]

        let ids = RSSService.extractArticleIDs(from: Feed.rss(feed))
        XCTAssertEqual(ids, ["https://example.com/article"])
    }

    func testExtractArticleIDsFromAtom() {
        let feed = AtomFeed()
        let entry1 = AtomFeedEntry()
        entry1.id = "atom-id-1"
        let entry2 = AtomFeedEntry()
        entry2.id = "atom-id-2"
        feed.entries = [entry1, entry2]

        let ids = RSSService.extractArticleIDs(from: Feed.atom(feed))
        XCTAssertEqual(ids, ["atom-id-1", "atom-id-2"])
    }

    func testExtractArticleIDsFromEmptyFeed() {
        let feed = RSSFeed()
        feed.items = []

        let ids = RSSService.extractArticleIDs(from: Feed.rss(feed))
        XCTAssertTrue(ids.isEmpty)
    }

    func testUnreadComputationIntegration() {
        // Simulate: source has read articles a,b; feed now has a,b,c,d
        var source = Source(
            url: URL(string: "https://example.com")!,
            title: "Test",
            rssURL: URL(string: "https://example.com/rss")!
        )
        source.readArticleIDs = ["a", "b"]
        source.updateKnownArticles(["a", "b", "c", "d"])

        XCTAssertEqual(source.unreadCount, 2)

        source.markAllAsRead()
        XCTAssertEqual(source.unreadCount, 0)

        // New articles appear
        source.updateKnownArticles(["a", "b", "c", "d", "e"])
        XCTAssertEqual(source.unreadCount, 1)
    }
}
