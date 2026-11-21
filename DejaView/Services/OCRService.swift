import Foundation
import Vision

enum OCRService {
    /// Reads text from image data (accurate level, language correction on).
    /// Returns lines joined by newlines, or "" when nothing is found or recognition fails.
    nonisolated static func readText(from imageData: Data) async -> String {
        await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            // English plus Indonesian when this device supports it, else the default (English).
            if let supported = try? request.supportedRecognitionLanguages() {
                let wanted = ["en-US", "id-ID"].filter { supported.contains($0) }
                if !wanted.isEmpty { request.recognitionLanguages = wanted }
            }

            let handler = VNImageRequestHandler(data: imageData)
            do {
                try handler.perform([request])
            } catch {
                return ""
            }
            let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            return lines.joined(separator: "\n")
        }.value
    }
}
