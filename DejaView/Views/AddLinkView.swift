import SwiftUI
import SwiftData
import PhotosUI
import CoreTransferable
import AVFoundation
import UniformTypeIdentifiers

struct AddLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PostProcessor.self) private var processor
    @Environment(\.openURL) private var openURL

    @State private var linkText = ""
    @State private var errorMessage: String?
    @State private var pickedItem: PhotosPickerItem?
    @State private var showPhotos = false
    @State private var isLoadingImage = false
    @State private var showCamera = false
    @State private var capturedPhoto: UIImage?
    @State private var isRequestingCamera = false
    @State private var showCameraSettings = false
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
                        .listRowBackground(Color(.secondarySystemBackground))
                }

                Section {
                    Button("Pick a screenshot", systemImage: "photo.on.rectangle") {
                        linkFocused = false
                        errorMessage = nil
                        showPhotos = true
                    }
                    .disabled(isLoadingImage || isRequestingCamera)
                    .listRowBackground(Color(.secondarySystemBackground))

                    Button("Take a photo", systemImage: "camera") {
                        Task { await openCamera() }
                    }
                    .disabled(isLoadingImage || isRequestingCamera)
                    .listRowBackground(Color(.secondarySystemBackground))

                    if isLoadingImage {
                        ProgressView("Importing image…")
                    }
                } footer: {
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .surfaceForm()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Save a post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveLink)
                        .disabled(isLoadingImage || isRequestingCamera || linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: prefillFromClipboard)
        }
        .photosPicker(isPresented: $showPhotos, selection: $pickedItem, matching: .images)
        .task(id: pickedItem) {
            if let pickedItem { await saveScreenshot(pickedItem) }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: saveCapturedPhoto) {
            CameraPicker(
                onImage: { image in
                    capturedPhoto = image
                    showCamera = false
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .alert("Camera access is off", isPresented: $showCameraSettings) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow camera access in Settings to take a photo.")
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
        guard !isLoadingImage, !isRequestingCamera else { return }
        guard let url = Self.extractURL(from: linkText) else {
            errorMessage = "That doesn't look like a link"
            return
        }
        let post = SavedPost(urlString: url.absoluteString, platform: Platform.detect(from: url))
        insertAndProcess(post)
    }

    private func saveScreenshot(_ item: PhotosPickerItem) async {
        isLoadingImage = true
        defer {
            isLoadingImage = false
            if pickedItem == item { pickedItem = nil }
        }
        let image = try? await item.loadTransferable(type: ImportedPostImage.self)
        guard !Task.isCancelled else { return }
        guard let image, let jpeg = ImageTools.downscaledJPEG(image.data) else {
            errorMessage = "Couldn't import that image. Try downloading it in Photos or choose another image."
            return
        }
        insertAndProcess(SavedPost(platform: .screenshot, imageData: jpeg))
    }

    private func openCamera() async {
        guard !isLoadingImage, !isRequestingCamera else { return }
        linkFocused = false
        errorMessage = nil
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = "This device doesn't have a camera available. Pick an image from Photos instead."
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            isRequestingCamera = true
            defer { isRequestingCamera = false }
            if await AVCaptureDevice.requestAccess(for: .video) {
                showCamera = true
            } else {
                showCameraSettings = true
            }
        case .denied:
            showCameraSettings = true
        case .restricted:
            errorMessage = "Camera access is restricted on this device."
        @unknown default:
            errorMessage = "The camera isn't available right now."
        }
    }

    private func saveCapturedPhoto() {
        guard let image = capturedPhoto else { return }
        capturedPhoto = nil
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
        do {
            try modelContext.save()
        } catch {
            modelContext.delete(post)
            errorMessage = "Couldn't save this post. Please try again."
            return
        }
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

private struct ImportedPostImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { ImportedPostImage(data: $0) }
    }
}
