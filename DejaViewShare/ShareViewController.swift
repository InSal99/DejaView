import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let host = UIHostingController(rootView: ShareView())
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)

        Task { @MainActor in
            await saveSharedItem()
            try? await Task.sleep(for: .seconds(1))
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    /// Saves one URL, image, or text containing a URL as a `.pending` post. Runs no model.
    @MainActor
    private func saveSharedItem() async {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []

        var post: SavedPost?

        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }),
           let url = await loadURL(from: provider) {
            post = SavedPost(urlString: url.absoluteString, platform: Platform.detect(from: url))
        } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }),
                  let data = await loadImageData(from: provider),
                  let jpeg = ImageTools.downscaledJPEG(data) {
            post = SavedPost(platform: .screenshot, imageData: jpeg)
        } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }),
                  let text = await loadText(from: provider),
                  let url = Self.firstURL(in: text) {
            post = SavedPost(urlString: url.absoluteString, platform: Platform.detect(from: url))
        }

        guard let post else { return }
        post.status = .pending
        let context = SharedContainer.container.mainContext
        context.insert(post)
        try? context.save()
    }

    // MARK: Loading

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        let item = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier)
        if let url = item as? URL, url.scheme?.hasPrefix("http") == true { return url }
        if let text = item as? String { return Self.firstURL(in: text) }
        return nil
    }

    private func loadText(from provider: NSItemProvider) async -> String? {
        let item = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier)
        return item as? String
    }

    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        let item = try? await provider.loadItem(forTypeIdentifier: UTType.image.identifier)
        if let url = item as? URL { return try? Data(contentsOf: url) }
        if let data = item as? Data { return data }
        if let image = item as? UIImage { return image.jpegData(compressionQuality: 1) }
        return nil
    }

    private static func firstURL(in text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        return detector?.matches(in: text, range: range)
            .compactMap(\.url)
            .first { $0.scheme == "http" || $0.scheme == "https" }
    }
}
