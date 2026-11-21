import Foundation
import LinkPresentation

struct LinkPreview {
    var title: String = ""
    var caption: String = ""
    var imageData: Data?
}

enum LinkFetcher {
    private static let timeout: TimeInterval = 10

    /// Never throws. Any failure returns empty fields.
    static func fetch(_ url: URL) async -> LinkPreview {
        async let lp = fetchLinkPresentation(url)
        async let html = fetchHTMLMeta(url)
        let (lpResult, htmlResult) = await (lp, html)

        let title = firstNonEmpty(lpResult.title, htmlResult.title)
        let caption = firstNonEmpty(htmlResult.description, lpResult.title, htmlResult.title)
        return LinkPreview(title: title, caption: caption, imageData: lpResult.imageData)
    }

    // MARK: LinkPresentation

    private struct LPResult { var title = ""; var imageData: Data? }

    private static func fetchLinkPresentation(_ url: URL) async -> LPResult {
        let provider = LPMetadataProvider()
        provider.timeout = timeout
        guard let metadata = try? await provider.startFetchingMetadata(for: url) else { return LPResult() }

        var result = LPResult(title: metadata.title ?? "")
        if let imageProvider = metadata.imageProvider {
            result.imageData = await loadImageData(from: imageProvider)
        }
        return result
    }

    private static func loadImageData(from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                guard let data else { return continuation.resume(returning: nil) }
                continuation.resume(returning: ImageTools.downscaledJPEG(data))
            }
        }
    }

    // MARK: HTML backup (og:title, og:description)

    private struct HTMLResult { var title = ""; var description = "" }

    private static func fetchHTMLMeta(_ url: URL) async -> HTMLResult {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        // Many sites only serve meta tags to link-preview crawlers.
        request.setValue("facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.8", forHTTPHeaderField: "Accept-Language")

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return HTMLResult() }
        let html = String(decoding: data.prefix(512_000), as: UTF8.self)
        return HTMLResult(
            title: metaContent(property: "og:title", in: html),
            description: firstNonEmpty(
                metaContent(property: "og:description", in: html),
                metaContent(property: "twitter:description", in: html),
                metaContent(property: "description", in: html)
            )
        )
    }

    /// Finds `<meta property|name="X" content="…">` in either attribute order.
    private static func metaContent(property: String, in html: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: property)
        let patterns = [
            #"<meta[^>]+(?:property|name)\s*=\s*["']"# + escaped + #"["'][^>]*?content\s*=\s*"([^"]*)""#,
            #"<meta[^>]+(?:property|name)\s*=\s*["']"# + escaped + #"["'][^>]*?content\s*=\s*'([^']*)'"#,
            #"<meta[^>]+content\s*=\s*"([^"]*)"[^>]*?(?:property|name)\s*=\s*["']"# + escaped + #"["']"#,
            #"<meta[^>]+content\s*=\s*'([^']*)'[^>]*?(?:property|name)\s*=\s*["']"# + escaped + #"["']"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  let range = Range(match.range(at: 1), in: html) else { continue }
            let value = decodeEntities(String(html[range])).trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { return value }
        }
        return ""
    }

    private static func decodeEntities(_ text: String) -> String {
        var result = text
        let named = ["&amp;": "&", "&quot;": "\"", "&#39;": "'", "&#x27;": "'", "&apos;": "'", "&lt;": "<", "&gt;": ">", "&nbsp;": " "]
        for (entity, char) in named { result = result.replacingOccurrences(of: entity, with: char) }
        return result
    }

    private static func firstNonEmpty(_ values: String...) -> String {
        values.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? ""
    }
}

#if DEBUG
extension LinkFetcher {
    /// Call from a `.task` or button while testing: prints what comes back for each sample link.
    /// Replace the samples with real post links from each platform.
    static func debugPrintSamples(_ samples: [String] = [
        "https://www.instagram.com/p/EXAMPLE/",
        "https://www.tiktok.com/@scout2015/video/6718335390845095173",
        "https://www.threads.net/@zuck/post/EXAMPLE",
        "https://x.com/Apple/status/1",
        "https://www.facebook.com/facebook/posts/EXAMPLE"
    ]) async {
        for sample in samples {
            guard let url = URL(string: sample) else { continue }
            let started = Date()
            let preview = await fetch(url)
            let seconds = String(format: "%.1f", Date().timeIntervalSince(started))
            print("""
            [LinkFetcher] \(Platform.detect(from: url).displayName) (\(seconds)s) \(sample)
              title:   \(preview.title.isEmpty ? "—" : preview.title)
              caption: \(preview.caption.isEmpty ? "—" : preview.caption)
              image:   \(preview.imageData.map { "\($0.count) bytes" } ?? "—")
            """)
        }
    }
}
#endif
