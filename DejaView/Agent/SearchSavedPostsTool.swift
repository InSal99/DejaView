import Foundation
import FoundationModels
import Observation

struct SearchSavedPostsTool: Tool {
    let name = "searchSavedPosts"
    let description = "Finds posts the user saved, by category, date, platform and keywords."
    let library: LibrarySearch

    @Generable
    struct Arguments {
        @Guide(description: "Category only if the user clearly names one, otherwise any")
        var category: CategoryFilter
        @Guide(description: "Time range the user mentions, otherwise any")
        var dateRange: DateRangeOption
        @Guide(description: "Platform only if the user names one, otherwise any")
        var platform: PlatformFilter
        @Guide(description: "Up to 5 topic words from the request", .maximumCount(5))
        var keywords: [String]
    }

    func call(arguments: Arguments) async throws -> String {
        await library.run(arguments)
    }
}

@MainActor
@Observable
final class LibrarySearch {
    private let posts: [SavedPost]
    private let question: String
    private(set) var results: [SearchResult] = []
    private(set) var label = ""
    private(set) var relaxedNote: String?
    private(set) var didSearch = false

    init(posts: [SavedPost], question: String) {
        self.posts = posts
        self.question = question
    }

    func run(_ arguments: SearchSavedPostsTool.Arguments) -> String {
        var words: [String] = []
        let questionWords = SearchEngine.keywords(fromRaw: question).filter { word in
            posts.contains { post in
                post.caption.lowercased().split { !$0.isLetter && !$0.isNumber }
                    .contains { $0.hasPrefix(word) }
            }
        }
        let rawWords = arguments.keywords.flatMap { SearchEngine.keywords(fromRaw: $0) } + questionWords
        for word in rawWords where !words.contains(word) {
            words.append(word)
            if words.count == 5 { break }
        }
        let query = SearchQuery(category: arguments.category, dateRange: arguments.dateRange, platform: arguments.platform, keywords: words)
        let search = SearchEngine.search(query, in: posts)
        results = search.results
        relaxedNote = search.relaxedNote
        didSearch = true

        var parts: [String] = []
        if arguments.category != .any { parts.append(arguments.category.rawValue) }
        switch arguments.dateRange {
        case .any: break
        case .today: parts.append("today")
        case .last7Days: parts.append("last 7 days")
        case .last30Days: parts.append("last 30 days")
        }
        if arguments.platform != .any { parts.append(arguments.platform.rawValue) }
        if !words.isEmpty { parts.append(words.joined(separator: ", ")) }
        label = "Searched: " + (parts.isEmpty ? "all posts" : parts.joined(separator: " · "))

        guard !results.isEmpty else { return "No saved posts matched. Nothing was found." }
        let descriptions = results.prefix(5).enumerated().map { index, result in
            let post = result.post
            let text = post.summary.isEmpty ? post.caption : post.summary
            return "\(index + 1)) \(String(text.prefix(180))) (\(post.category.displayName), \(post.platform.displayName))."
        }.joined(separator: " ")
        let prefix = relaxedNote.map { "No posts matched all filters. \($0) " } ?? ""
        return "\(prefix)Found \(results.count) saved posts: \(descriptions) Only describe these posts."
    }
}
