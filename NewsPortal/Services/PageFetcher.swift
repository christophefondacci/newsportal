import Foundation

struct PageMetadata {
    let title: String
    let rssURL: URL?
}

protocol PageFetching {
    func fetch(url: URL) async throws -> PageMetadata
}

class PageFetcher: PageFetching {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(url: URL) async throws -> PageMetadata {
        let (data, _) = try await session.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let title = Self.extractTitle(from: html) ?? url.host ?? url.absoluteString
        let rssURL = Self.extractRSSLink(from: html, baseURL: url)
        return PageMetadata(title: title, rssURL: rssURL)
    }

    static func extractTitle(from html: String) -> String? {
        guard let titleStart = html.range(of: "<title", options: .caseInsensitive),
              let tagClose = html.range(of: ">", range: titleStart.upperBound..<html.endIndex),
              let titleEnd = html.range(of: "</title>", options: .caseInsensitive, range: tagClose.upperBound..<html.endIndex)
        else { return nil }

        let title = String(html[tagClose.upperBound..<titleEnd.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : decodeHTMLEntities(title)
    }

    static func extractRSSLink(from html: String, baseURL: URL) -> URL? {
        let pattern = #"<link[^>]+type\s*=\s*"application/(rss|atom)\+xml"[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html))
        else { return nil }

        let tag = String(html[Range(match.range, in: html)!])

        let hrefPattern = #"href\s*=\s*"([^"]+)""#
        guard let hrefRegex = try? NSRegularExpression(pattern: hrefPattern, options: .caseInsensitive),
              let hrefMatch = hrefRegex.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)),
              let hrefRange = Range(hrefMatch.range(at: 1), in: tag)
        else { return nil }

        let href = String(tag[hrefRange])
        if let absolute = URL(string: href), absolute.scheme != nil {
            return absolute
        }
        return URL(string: href, relativeTo: baseURL)?.absoluteURL
    }

    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }
}
