import Foundation
import FoundationModels

enum ModelFailure {
    case tooLong, unsafe, refused, unsupportedLanguage, busy, notReady, toolFailed, other
}

enum ModelErrors {
    /// Xcode 27: the framework throws `LanguageModelError`, `SystemLanguageModel.Error`
    /// and `LanguageModelSession.Error`. `GenerationError` is not thrown here.
    static func classify(_ error: Error) -> ModelFailure {
        if error is LanguageModelSession.ToolCallError { return .toolFailed }
        if #available(iOS 27.0, *) {
            if let e = error as? LanguageModelError {
                switch e {
                case .contextSizeExceeded: return .tooLong
                case .guardrailViolation: return .unsafe
                case .refusal: return .refused
                case .unsupportedLanguageOrLocale: return .unsupportedLanguage
                case .rateLimited, .timeout: return .busy
                default: return .other
                }
            }
            if case .assetsUnavailable = error as? SystemLanguageModel.Error { return .notReady }
            if error as? LanguageModelSession.Error == .concurrentRequests { return .busy }
        }
        return .other
    }

    static func message(for failure: ModelFailure) -> String {
        switch failure {
        case .tooLong: "This post is too long to summarize; saved without a summary."
        case .unsafe: "Couldn't summarize this post."
        case .refused: "The model declined to summarize this post."
        case .unsupportedLanguage: "This language isn't supported yet."
        case .busy: "The model is busy; try again in a moment."
        case .notReady: "Apple Intelligence is still downloading."
        case .toolFailed: "Search failed; nothing was changed."
        case .other: "Something went wrong; saved without a summary."
        }
    }
}
