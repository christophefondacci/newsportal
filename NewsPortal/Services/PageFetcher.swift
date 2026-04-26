import AppKit
import Foundation

struct PageMetadata {
    let title: String
    let rssURL: URL?
    let faviconURL: URL?
}

protocol PageFetching {
    func fetch(url: URL) async throws -> PageMetadata
    func fetchFavicon(for url: URL, faviconURL: URL?) async -> Data?
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
        let faviconURL = Self.extractFaviconLink(from: html, baseURL: url)
        return PageMetadata(title: title, rssURL: rssURL, faviconURL: faviconURL)
    }

    func fetchFavicon(for url: URL, faviconURL: URL?) async -> Data? {
        let candidates: [URL] = [
            faviconURL,
            url.appendingPathComponent("favicon.ico"),
            url.appendingPathComponent("apple-touch-icon.png"),
        ].compactMap { $0 }

        for candidate in candidates {
            if let data = await downloadValidImage(from: candidate) {
                return data
            }
        }

        // Last resort: use Google's favicon service
        if let host = url.host,
           let googleURL = URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(host)"),
           let data = await downloadValidImage(from: googleURL) {
            return data
        }

        return nil
    }

    private func downloadValidImage(from url: URL) async -> Data? {
        guard let (data, response) = try? await session.data(from: url),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              !data.isEmpty else { return nil }

        // If the content type is SVG, convert to a rasterized PNG via NSImage
        let contentType = http.value(forHTTPHeaderField: "Content-Type") ?? ""
        if contentType.contains("svg") {
            return Self.rasterizeSVG(data)
        }

        // Verify NSImage can decode the data
        guard NSImage(data: data) != nil else { return nil }
        return data
    }

    private static func rasterizeSVG(_ svgData: Data) -> Data? {
        guard let svgImage = NSImage(data: svgData), svgImage.isValid else { return nil }
        let size = NSSize(width: 64, height: 64)
        let resized = NSImage(size: size)
        resized.lockFocus()
        svgImage.draw(in: NSRect(origin: .zero, size: size),
                      from: NSRect(origin: .zero, size: svgImage.size),
                      operation: .copy, fraction: 1.0)
        resized.unlockFocus()
        guard let tiff = resized.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }
        return png
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

    static func extractFaviconLink(from html: String, baseURL: URL) -> URL? {
        // Match <link> tags with rel containing "icon" (covers "icon", "shortcut icon", "apple-touch-icon")
        let pattern = #"<link[^>]+rel\s*=\s*"[^"]*icon[^"]*"[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }

        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        let hrefPattern = #"href\s*=\s*"([^"]+)""#
        guard let hrefRegex = try? NSRegularExpression(pattern: hrefPattern, options: .caseInsensitive) else { return nil }

        // Prefer the first "icon" or "shortcut icon" match
        for match in matches {
            let tag = String(html[Range(match.range, in: html)!])
            guard let hrefMatch = hrefRegex.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)),
                  let hrefRange = Range(hrefMatch.range(at: 1), in: tag) else { continue }

            let href = String(tag[hrefRange])
            if let absolute = URL(string: href), absolute.scheme != nil {
                return absolute
            }
            return URL(string: href, relativeTo: baseURL)?.absoluteURL
        }
        return nil
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
