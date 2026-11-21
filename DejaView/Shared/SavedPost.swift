import Foundation
import SwiftData

enum PostStatus: String, Codable { case pending, processed, needsReview }

enum SourceKind: String, CaseIterable {
    case post, screenshot, link
}

@Model
final class SavedPost {
    @Attribute(.unique) var id: UUID
    var urlString: String?
    var platformRaw: String
    var savedAt: Date
    var caption: String              // original text from the link preview
    var ocrText: String              // text read from the image
    var detectedLanguage: String     // "en", "id", …
    var englishText: String          // translation sent to the model ("" if not needed)
    @Attribute(.externalStorage) var imageData: Data?
    var summary: String
    var categoryRaw: String
    var tags: [String]
    var statusRaw: String
    var statusMessage: String        // e.g. "No text found — add a note"
    var userNote: String
    var processedWithAI: Bool
    // Added in the improvement round. Defaults let SwiftData migrate existing stores.
    var title: String = ""
    var summaryDescription: String = ""
    var keyPoints: [String] = []

    init(urlString: String? = nil, platform: Platform, imageData: Data? = nil) {
        self.id = UUID()
        self.urlString = urlString
        self.platformRaw = platform.rawValue
        self.savedAt = Date()
        self.caption = ""
        self.ocrText = ""
        self.detectedLanguage = ""
        self.englishText = ""
        self.imageData = imageData
        self.summary = ""
        self.categoryRaw = PostCategory.other.rawValue
        self.tags = []
        self.statusRaw = PostStatus.pending.rawValue
        self.statusMessage = ""
        self.userNote = ""
        self.processedWithAI = false
    }

    var platform: Platform { Platform(rawValue: platformRaw) ?? .web }

    /// Best available title: title, else summary, else the first 60 characters of the caption.
    var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty { return trimmedTitle }
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSummary.isEmpty { return trimmedSummary }
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCaption.isEmpty { return String(trimmedCaption.prefix(60)) }
        return "Untitled post"
    }

    var sourceKind: SourceKind {
        switch platform {
        case .screenshot: .screenshot
        case .web: .link
        default: .post
        }
    }

    var category: PostCategory {
        get { PostCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var status: PostStatus {
        get { PostStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}
