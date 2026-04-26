import XCTest
@testable import NewsPortal

final class PageFetcherTests: XCTestCase {

    // MARK: - Title extraction

    func testExtractSimpleTitle() {
        let html = "<html><head><title>Hello World</title></head></html>"
        XCTAssertEqual(PageFetcher.extractTitle(from: html), "Hello World")
    }

    func testExtractTitleWithWhitespace() {
        let html = "<html><head><title>  Hello World  \n</title></head></html>"
        XCTAssertEqual(PageFetcher.extractTitle(from: html), "Hello World")
    }

    func testExtractTitleWithHTMLEntities() {
        let html = "<html><head><title>News &amp; Updates</title></head></html>"
        XCTAssertEqual(PageFetcher.extractTitle(from: html), "News & Updates")
    }

    func testExtractTitleCaseInsensitive() {
        let html = "<html><head><TITLE>Hello</TITLE></head></html>"
        XCTAssertEqual(PageFetcher.extractTitle(from: html), "Hello")
    }

    func testExtractTitleReturnsNilWhenMissing() {
        let html = "<html><head></head><body>No title here</body></html>"
        XCTAssertNil(PageFetcher.extractTitle(from: html))
    }

    func testExtractTitleReturnsNilWhenEmpty() {
        let html = "<html><head><title></title></head></html>"
        XCTAssertNil(PageFetcher.extractTitle(from: html))
    }

    // MARK: - RSS link extraction

    func testExtractRSSLink() {
        let html = """
        <html><head>
        <link rel="alternate" type="application/rss+xml" href="https://example.com/feed.xml">
        </head></html>
        """
        let base = URL(string: "https://example.com")!
        let result = PageFetcher.extractRSSLink(from: html, baseURL: base)
        XCTAssertEqual(result?.absoluteString, "https://example.com/feed.xml")
    }

    func testExtractAtomLink() {
        let html = """
        <html><head>
        <link rel="alternate" type="application/atom+xml" href="/feed.atom">
        </head></html>
        """
        let base = URL(string: "https://example.com")!
        let result = PageFetcher.extractRSSLink(from: html, baseURL: base)
        XCTAssertEqual(result?.absoluteString, "https://example.com/feed.atom")
    }

    func testExtractRSSLinkRelativeURL() {
        let html = """
        <html><head>
        <link rel="alternate" type="application/rss+xml" href="/rss">
        </head></html>
        """
        let base = URL(string: "https://example.com/section/")!
        let result = PageFetcher.extractRSSLink(from: html, baseURL: base)
        XCTAssertEqual(result?.absoluteString, "https://example.com/rss")
    }

    func testExtractRSSLinkReturnsNilWhenMissing() {
        let html = "<html><head><title>No feed</title></head></html>"
        let base = URL(string: "https://example.com")!
        XCTAssertNil(PageFetcher.extractRSSLink(from: html, baseURL: base))
    }

    func testExtractRSSLinkIgnoresStylesheet() {
        let html = """
        <html><head>
        <link rel="stylesheet" type="text/css" href="/style.css">
        </head></html>
        """
        let base = URL(string: "https://example.com")!
        XCTAssertNil(PageFetcher.extractRSSLink(from: html, baseURL: base))
    }
}
