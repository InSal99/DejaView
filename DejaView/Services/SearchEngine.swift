import Foundation
import FoundationModels

@Generable
enum CategoryFilter: String, CaseIterable {
    case any, design, foodRecipes, travel, tech, tipsLearning, shopping, entertainment, other
}

@Generable
enum DateRangeOption: String, CaseIterable {
    case any, today, last7Days, last30Days
}

@Generable
enum PlatformFilter: String, CaseIterable {
    case any, instagram, tiktok, threads, x, facebook, web, screenshot
}

struct SearchQuery {
    var category: CategoryFilter = .any
    var dateRange: DateRangeOption = .any
    var platform: PlatformFilter = .any
    var keywords: [String] = []
}

struct SearchResult: Identifiable {
    let post: SavedPost
    let reason: String
    var id: UUID { post.id }
}

enum SearchEngine {
    static func keywords(fromRaw text: String) -> [String] {
        let stopWords: Set<String> = ["the", "my", "posts", "saved", "i", "a", "from", "on", "about"]
        let words = text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        var result: [String] = []
        for word in words where !stopWords.contains(word) && !result.contains(word) {
            result.append(word)
            if result.count == 5 { break }
        }
        return result
    }

    static func search(_ query: SearchQuery, in posts: [SavedPost], now: Date = .now) -> (results: [SearchResult], relaxedNote: String?) {
        var keywords: [String] = []
        for word in query.keywords.flatMap({ Self.keywords(fromRaw: $0) }) where !keywords.contains(word) {
            keywords.append(word)
            if keywords.count == 5 { break }
        }
        var effectiveQuery = query
        var matches = matching(effectiveQuery, keywords: keywords, posts: posts, now: now)
        var note: String?

        if matches.isEmpty && effectiveQuery.dateRange != .any {
            effectiveQuery.dateRange = .any
            matches = matching(effectiveQuery, keywords: keywords, posts: posts, now: now)
            if !matches.isEmpty { note = "No exact match; showing results from any date." }
        }
        if matches.isEmpty && effectiveQuery.category != .any && !keywords.isEmpty {
            effectiveQuery.category = .any
            matches = matching(effectiveQuery, keywords: keywords, posts: posts, now: now)
            if !matches.isEmpty {
                note = query.dateRange == .any
                    ? "No exact match; showing results from any category."
                    : "No exact match; showing results from any date and category."
            }
        }
        if matches.isEmpty && effectiveQuery.platform != .any && !keywords.isEmpty {
            effectiveQuery.platform = .any
            matches = matching(effectiveQuery, keywords: keywords, posts: posts, now: now)
            if !matches.isEmpty { note = "No exact match; showing keyword matches across all platforms." }
        }
        return (Array(matches.prefix(20)), note)
    }

    private static func matching(_ query: SearchQuery, keywords: [String], posts: [SavedPost], now: Date) -> [SearchResult] {
        let calendar = Calendar.current
        let start: Date?
        switch query.dateRange {
        case .any: start = nil
        case .today: start = calendar.startOfDay(for: now)
        case .last7Days: start = calendar.date(byAdding: .day, value: -7, to: now)
        case .last30Days: start = calendar.date(byAdding: .day, value: -30, to: now)
        }

        var scored: [(result: SearchResult, score: Int)] = []
        for post in posts {
            guard query.category == .any || post.category.rawValue == query.category.rawValue,
                  query.platform == .any || post.platform.rawValue == query.platform.rawValue else { continue }
            if let start, !(start...now).contains(post.savedAt) { continue }

            let fields: [(name: String, text: String, weight: Int)] = [
                ("tags", post.tags.joined(separator: " "), 3),
                ("summary", post.summary, 2),
                ("caption", post.caption, 1),
                ("image text", post.ocrText, 1),
                ("translation", post.englishText, 1),
                ("note", post.userNote, 1)
            ]
            var score = 0
            var firstMatch: String?
            for keyword in keywords {
                for field in fields where containsPrefix(keyword, in: field.text) {
                    score += field.weight
                    if firstMatch == nil { firstMatch = "‘\(keyword)’ in \(field.name)" }
                }
            }
            guard keywords.isEmpty || score > 0 else { continue }
            let detail: String
            if let firstMatch {
                detail = firstMatch
            } else {
                switch query.dateRange {
                case .any: detail = post.platform.displayName
                case .today: detail = "today"
                case .last7Days: detail = "last 7 days"
                case .last30Days: detail = "last 30 days"
                }
            }
            scored.append((SearchResult(post: post, reason: "\(post.category.displayName) · \(detail)"), score))
        }
        return scored.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.result.post.savedAt != $1.result.post.savedAt { return $0.result.post.savedAt > $1.result.post.savedAt }
            return $0.result.id.uuidString < $1.result.id.uuidString
        }.map(\.result)
    }

    private static func containsPrefix(_ keyword: String, in text: String) -> Bool {
        let words = text.lowercased().split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.hasPrefix(keyword) }) { return true }
        guard keyword.count > 3, keyword.hasSuffix("s") else { return false }
        let singular = keyword.dropLast()
        return words.contains { $0.hasPrefix(singular) }
    }
}
