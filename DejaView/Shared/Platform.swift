import Foundation

enum Platform: String, Codable, CaseIterable {
    case instagram, tiktok, threads, x, facebook, web, screenshot

    static func detect(from url: URL) -> Platform {
        guard var host = url.host()?.lowercased() else { return .web }
        if host.hasPrefix("www.") { host.removeFirst(4) }

        func matches(_ domain: String) -> Bool {
            host == domain || host.hasSuffix("." + domain)
        }

        if matches("instagram.com") { return .instagram }
        if matches("tiktok.com") { return .tiktok }
        if matches("threads.net") || matches("threads.com") { return .threads }
        if matches("x.com") || matches("twitter.com") { return .x }
        if matches("facebook.com") || matches("fb.watch") || matches("fb.com") { return .facebook }
        return .web
    }

    /// SF Symbol for the kind of source. Never a platform logo.
    var symbol: String {
        switch self {
        case .screenshot: "photo"
        case .web: "globe"
        default: "text.bubble"
        }
    }

    var displayName: String {
        switch self {
        case .instagram: "Instagram"
        case .tiktok: "TikTok"
        case .threads: "Threads"
        case .x: "X"
        case .facebook: "Facebook"
        case .web: "Web"
        case .screenshot: "Screenshot"
        }
    }
}
