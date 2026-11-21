import Foundation
import SwiftData

enum PostStatus: String, Codable { case pending, processed, needsReview }

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

    var category: PostCategory {
        get { PostCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var status: PostStatus {
        get { PostStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}
