import SwiftUI
import SwiftData
import PhotosUI

struct AddLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PostProcessor.self) private var processor

    @State private var linkText = ""
    @State private var errorMessage: String?
    @State private var pickedItem: PhotosPickerItem?
    @State private var isLoadingImage = false
    @State private var showCamera = false
    @FocusState private var linkFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Paste a link", text: $linkText)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($linkFocused)
                        .submitLabel(.done)
                        .onSubmit(saveLink)
                        .onChange(of: linkText) { _, _ in errorMessage = nil }
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        Label("Pick a screenshot", systemImage: "photo.on.rectangle")
                    }
                    .disabled(isLoadingImage)

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take a photo", systemImage: "camera")
                        }
                        .disabled(isLoadingImage)
                    }
                }
            }
            .navigationTitle("Save a post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveLink)
                        .disabled(linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: pickedItem) { _, item in
                if let item { Task { await saveScreenshot(item) } }
            }
            .onAppear(perform: prefillFromClipboard)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(
                    onImage: { image in
                        showCamera = false
                        savePhoto(image)
                    },
                    onCancel: { showCamera = false }
                )
                .ignoresSafeArea()
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: Actions

    private func prefillFromClipboard() {
        guard linkText.isEmpty else { return }
        let pasteboard = UIPasteboard.general
        if pasteboard.hasURLs, let url = pasteboard.url, Self.isWebURL(url) {
            linkText = url.absoluteString
        } else if pasteboard.hasStrings, let text = pasteboard.string,
                  let url = Self.extractURL(from: text) {
            linkText = url.absoluteString
        }
    }

    private func saveLink() {
        guard let url = Self.extractURL(from: linkText) else {
            errorMessage = "That doesn't look like a link"
            return
        }
        let post = SavedPost(urlString: url.absoluteString, platform: Platform.detect(from: url))
        insertAndProcess(post)
    }

    private func saveScreenshot(_ item: PhotosPickerItem) async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let jpeg = ImageTools.downscaledJPEG(data) else {
            errorMessage = "Couldn't read that image"
            pickedItem = nil
            return
        }
        insertAndProcess(SavedPost(platform: .screenshot, imageData: jpeg))
    }

    private func savePhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9),
              let jpeg = ImageTools.downscaledJPEG(data) else {
            errorMessage = "Couldn't read that photo"
            return
        }
        insertAndProcess(SavedPost(platform: .screenshot, imageData: jpeg))
    }

    private func insertAndProcess(_ post: SavedPost) {
        post.status = .pending
        modelContext.insert(post)
        try? modelContext.save()
        let context = modelContext
        let processor = processor
        dismiss()
        Task { await processor.processPending(in: context) }
    }

    // MARK: URL helpers

    private static func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return false }
        return url.host()?.contains(".") == true
    }

    /// Accepts a bare URL or text containing one ("www.x.com/…" gets https://).
    static func extractURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if !trimmed.contains(" "), let url = URL(string: trimmed), isWebURL(url) { return url }

        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            for match in detector.matches(in: trimmed, range: range) {
                if let url = match.url, isWebURL(url) { return url }
            }
        }
        return nil
    }
}
