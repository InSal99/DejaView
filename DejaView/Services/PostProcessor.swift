import Foundation
import SwiftData
import NaturalLanguage
import FoundationModels

@MainActor @Observable
final class PostProcessor {
    private(set) var isProcessing = false

    init() {}

    /// Processes every `.pending` post, one at a time. A post never stays `.pending`.
    func processPending(in context: ModelContext) async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        let pendingRaw = PostStatus.pending.rawValue
        // Re-fetch until none are left, so posts saved during processing are picked up too.
        while true {
            let descriptor = FetchDescriptor<SavedPost>(
                predicate: #Predicate { $0.statusRaw == pendingRaw },
                sortBy: [SortDescriptor(\.savedAt)]
            )
            guard let pending = try? context.fetch(descriptor), !pending.isEmpty else { return }
            for post in pending {
                await process(post)
                if post.status == .pending { post.status = .needsReview }   // safety net
                try? context.save()
            }
        }
    }

    // MARK: One post

    private func process(_ post: SavedPost) async {
        // 1. Link text
        if post.caption.isEmpty, let urlString = post.urlString, let url = URL(string: urlString) {
            let preview = await LinkFetcher.fetch(url)
            post.caption = preview.caption
            if post.imageData == nil { post.imageData = preview.imageData }
        }

        // 2. OCR (Sprint 2)
        // TODO(B4): if post.imageData != nil && post.ocrText.isEmpty { post.ocrText = await OCRService.read(...) }

        // 3. Combined text
        let combined = [post.caption, post.ocrText, post.userNote]
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !combined.isEmpty else {
            post.summary = ""
            post.status = .needsReview
            post.statusMessage = "No text found — add a note"
            post.processedWithAI = false
            return
        }

        // 4. Language
        post.detectedLanguage = Self.detectLanguage(combined)
        // TODO(B2b): if Indonesian fails in B0, translate to English here and set post.englishText.
        let textForModel = post.englishText.isEmpty ? combined : post.englishText

        // 5. Trim
        var text = Self.trimmed(textForModel, maxCharacters: 1_500)

        // 6. Model
        if let reason = PostAnalyzer.unavailableReason {
            fallback(post, text: combined, message: reason)
            return
        }
        text = await fitToContext(text)

        do {
            let analysis = try await PostAnalyzer.analyze(text: text)
            post.summary = analysis.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            post.category = analysis.category
            post.tags = Self.cleanTags(analysis.tags)
            post.status = analysis.needsReview ? .needsReview : .processed
            post.statusMessage = ""
            post.processedWithAI = true
        } catch {
            // 7. TODO(B2b): on .unsupportedLanguage and not yet translated, translate and retry once.
            fallback(post, text: combined, message: ModelErrors.message(for: ModelErrors.classify(error)))
        }
    }

    // MARK: Fallback (model off or failed)

    private func fallback(_ post: SavedPost, text: String, message: String) {
        post.summary = String(text.replacingOccurrences(of: "\n", with: " ").prefix(120))
        post.tags = Self.hashtags(in: post.caption)
        post.category = .other
        post.status = .needsReview
        post.statusMessage = message
        post.processedWithAI = false
    }

    // MARK: Helpers

    /// Keeps the prompt under half of the model's context window when the token count is available.
    private func fitToContext(_ text: String) async -> String {
        var text = text
        let budget = SystemLanguageModel.default.contextSize / 2
        for _ in 0..<4 {
            guard let used = try? await SystemLanguageModel.default.tokenCount(for: PostAnalyzer.prompt(for: text)),
                  used > budget, text.count > 200 else { break }
            text = String(text.prefix(text.count / 2))
        }
        return text
    }

    private static func trimmed(_ text: String, maxCharacters: Int) -> String {
        text.count <= maxCharacters ? text : String(text.prefix(maxCharacters))
    }

    private static func detectLanguage(_ text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue ?? ""
    }

    private static func cleanTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags
            .map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "# ").union(.whitespacesAndNewlines)) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    /// Hashtags from the caption, lowercased, without `#`, max 5.
    private static func hashtags(in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"#([\p{L}\p{N}_]+)"#) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        var seen = Set<String>()
        var result: [String] = []
        for match in regex.matches(in: text, range: range) {
            guard let r = Range(match.range(at: 1), in: text) else { continue }
            let tag = text[r].lowercased()
            if seen.insert(tag).inserted { result.append(tag) }
            if result.count == 5 { break }
        }
        return result
    }
}
