import XCTest
@testable import NewsPortal

@MainActor
final class SourceStoreTests: XCTestCase {

    private func makeTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    func testAddSource() {
        let store = SourceStore(fileURL: makeTempFileURL())
        let source = Source(url: URL(string: "https://example.com")!, title: "Example")
        store.add(source)

        XCTAssertEqual(store.sources.count, 1)
        XCTAssertEqual(store.sources.first?.title, "Example")
    }

    func testRemoveByID() {
        let store = SourceStore(fileURL: makeTempFileURL())
        let source = Source(url: URL(string: "https://example.com")!, title: "Example")
        store.add(source)
        store.remove(id: source.id)

        XCTAssertTrue(store.sources.isEmpty)
    }

    func testSortedSources() {
        let store = SourceStore(fileURL: makeTempFileURL())
        store.add(Source(url: URL(string: "https://c.com")!, title: "Charlie"))
        store.add(Source(url: URL(string: "https://a.com")!, title: "Alpha"))
        store.add(Source(url: URL(string: "https://b.com")!, title: "Bravo"))

        let titles = store.sortedSources.map(\.title)
        XCTAssertEqual(titles, ["Alpha", "Bravo", "Charlie"])
    }

    func testSortedSourcesCaseInsensitive() {
        let store = SourceStore(fileURL: makeTempFileURL())
        store.add(Source(url: URL(string: "https://a.com")!, title: "alpha"))
        store.add(Source(url: URL(string: "https://b.com")!, title: "Bravo"))

        let titles = store.sortedSources.map(\.title)
        XCTAssertEqual(titles, ["alpha", "Bravo"])
    }

    func testPersistenceRoundTrip() {
        let fileURL = makeTempFileURL()

        let store1 = SourceStore(fileURL: fileURL)
        store1.add(Source(url: URL(string: "https://example.com")!, title: "Example"))
        store1.add(Source(url: URL(string: "https://other.com")!, title: "Other"))

        let store2 = SourceStore(fileURL: fileURL)
        XCTAssertEqual(store2.sources.count, 2)
        XCTAssertTrue(store2.sources.contains(where: { $0.title == "Example" }))
        XCTAssertTrue(store2.sources.contains(where: { $0.title == "Other" }))
    }

    func testMarkAsRead() {
        let store = SourceStore(fileURL: makeTempFileURL())
        var source = Source(url: URL(string: "https://example.com")!, title: "Example")
        source.knownArticleIDs = ["a", "b"]
        store.add(source)

        store.markAsRead(id: source.id)

        XCTAssertEqual(store.sources.first?.unreadCount, 0)
    }

    func testUpdateKnownArticles() {
        let store = SourceStore(fileURL: makeTempFileURL())
        let source = Source(url: URL(string: "https://example.com")!, title: "Example")
        store.add(source)

        store.updateKnownArticles(id: source.id, articleIDs: ["x", "y", "z"])

        XCTAssertEqual(store.sources.first?.knownArticleIDs, ["x", "y", "z"])
        XCTAssertEqual(store.sources.first?.unreadCount, 3)
    }

    func testUpdateSource() {
        let store = SourceStore(fileURL: makeTempFileURL())
        var source = Source(url: URL(string: "https://example.com")!, title: "Old Title")
        store.add(source)

        source.title = "New Title"
        store.update(source)

        XCTAssertEqual(store.sources.first?.title, "New Title")
    }
}
