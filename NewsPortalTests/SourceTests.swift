import XCTest
@testable import NewsPortal

final class SourceTests: XCTestCase {

    func testUnreadCountWithNoArticles() {
        let source = Source(url: URL(string: "https://example.com")!, title: "Example")
        XCTAssertEqual(source.unreadCount, 0)
    }

    func testUnreadCountWithKnownArticles() {
        var source = Source(url: URL(string: "https://example.com")!, title: "Example")
        source.knownArticleIDs = ["a", "b", "c"]
        XCTAssertEqual(source.unreadCount, 3)
    }

    func testUnreadCountAfterPartialRead() {
        var source = Source(url: URL(string: "https://example.com")!, title: "Example")
        source.knownArticleIDs = ["a", "b", "c"]
        source.readArticleIDs = ["a"]
        XCTAssertEqual(source.unreadCount, 2)
    }

    func testMarkAllAsRead() {
        var source = Source(url: URL(string: "https://example.com")!, title: "Example")
        source.knownArticleIDs = ["a", "b", "c"]
        XCTAssertEqual(source.unreadCount, 3)

        source.markAllAsRead()
        XCTAssertEqual(source.unreadCount, 0)
        XCTAssertTrue(source.readArticleIDs.isSuperset(of: ["a", "b", "c"]))
    }

    func testMarkAllAsReadPreservesOldReads() {
        var source = Source(url: URL(string: "https://example.com")!, title: "Example")
        source.readArticleIDs = ["old"]
        source.knownArticleIDs = ["a", "b"]

        source.markAllAsRead()
        XCTAssertTrue(source.readArticleIDs.contains("old"))
        XCTAssertTrue(source.readArticleIDs.contains("a"))
        XCTAssertTrue(source.readArticleIDs.contains("b"))
    }

    func testUpdateKnownArticles() {
        var source = Source(url: URL(string: "https://example.com")!, title: "Example")
        source.knownArticleIDs = ["a", "b"]
        source.updateKnownArticles(["c", "d"])
        XCTAssertEqual(source.knownArticleIDs, ["c", "d"])
    }

    func testCodableRoundTrip() throws {
        var source = Source(
            url: URL(string: "https://example.com")!,
            title: "Example",
            rssURL: URL(string: "https://example.com/feed.xml")
        )
        source.knownArticleIDs = ["a", "b"]
        source.readArticleIDs = ["a"]

        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(Source.self, from: data)

        XCTAssertEqual(source, decoded)
        XCTAssertEqual(decoded.title, "Example")
        XCTAssertEqual(decoded.rssURL?.absoluteString, "https://example.com/feed.xml")
        XCTAssertEqual(decoded.unreadCount, 1)
    }

    func testCodableWithoutRSS() throws {
        let source = Source(url: URL(string: "https://example.com")!, title: "Example")

        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(Source.self, from: data)

        XCTAssertEqual(source, decoded)
        XCTAssertNil(decoded.rssURL)
    }
}
