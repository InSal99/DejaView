import SwiftUI
import SwiftData

struct PostDetailView: View {
    @Bindable var post: SavedPost
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(PostProcessor.self) private var processor
    @State private var showingDelete = false
    @State private var showingFullImage = false
    @State private var showingRefine = false
    @State private var showingNote = false
    @State private var note = ""
    @State private var errorMessage: String?

    private var description: String {
        post.summaryDescription.isEmpty ? post.summary : post.summaryDescription
    }

    private var originalURL: URL? {
        guard let urlString = post.urlString, let url = URL(string: urlString),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero

                VStack(alignment: .leading, spacing: 24) {
                    header
                    summaryCard
                    keyPoints
                    tagChips
                    readSection
                    if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.red) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .dismissKeyboardOnTap()
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { note = post.userNote }
        .toolbar {
            Menu("Post options", systemImage: "ellipsis.circle") {
                Button("Refine with AI", systemImage: "wand.and.stars") { showingRefine = true }
                    .disabled(processor.isProcessing || post.status == .pending)
                Button("Retry with AI", systemImage: "arrow.clockwise") {
                    post.status = .pending
                    do {
                        try context.save()
                        errorMessage = nil
                        Task { await processor.processPending(in: context) }
                    } catch {
                        context.rollback()
                        errorMessage = "Couldn't retry this post. Please try again."
                    }
                }
                .disabled(processor.isProcessing)
                Button("Delete", systemImage: "trash", role: .destructive) { showingDelete = true }
            }
        }
        .sheet(isPresented: $showingRefine) { RefineSheet(post: post) }
        .sheet(isPresented: $showingNote) {
            NoteSheet(note: $note) { newNote in
                post.userNote = newNote
                note = newNote
                if newNote.isEmpty { save() } else { markReviewed() }
            }
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let data = post.imageData { FullImageView(imageData: data) }
        }
        .confirmationDialog("Delete this post?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(post)
                do { try context.save(); dismiss() } catch { context.rollback(); errorMessage = "Couldn't delete this post. Please try again." }
            }
        }
    }

    // MARK: Sections

    @ViewBuilder
    private var hero: some View {
        let image = PostImage(post: post).frame(height: 280).clipped()
        if post.imageData != nil {
            Button { showingFullImage = true } label: { image }
                .buttonStyle(.plain)
                .accessibilityLabel("Open image full screen")
        } else {
            image.accessibilityHidden(true)
        }
    }

    /// Category, title, one meta line, one quiet action.
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                categoryMenu
                Spacer()
            }
            Text(post.displayTitle)
                .font(.title2.bold())
            HStack(spacing: 16) {
                Label(post.platform.displayName, systemImage: post.platform.symbol)
                Label(post.savedAt.staticSaved, systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            if let originalURL {
                Link(destination: originalURL) {
                    Label("Open original", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .padding(.top, 4)
            }
        }
    }

    /// The summary and the user's own note share one card, with a single note action at the bottom.
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if post.status == .pending || !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI Summary", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)
                    Text(post.status == .pending ? "Processing…" : description)
                        .font(.body)
                }
            }
            if !post.userNote.isEmpty {
                if post.status == .pending || !description.isEmpty { Divider() }
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your note", systemImage: "note.text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(post.userNote)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }
            Button(post.userNote.isEmpty ? "Add note" : "Edit note", systemImage: post.userNote.isEmpty ? "plus" : "pencil") {
                note = post.userNote
                showingNote = true
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .surface(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var keyPoints: some View {
        if !post.keyPoints.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Key Points").font(.headline)
                ForEach(post.keyPoints, id: \.self) { point in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(.caption2))
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(point).font(.body)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tagChips: some View {
        if !post.tags.isEmpty {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .surface(in: Capsule())
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var categoryMenu: some View {
        Menu {
            Picker("Category", selection: $post.category) {
                ForEach(PostCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.symbol).tag(category)
                }
            }
        } label: {
            HStack(spacing: 4) {
                CategoryChip(category: post.category)
                Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel("Category: \(post.category.displayName)")
        .onChange(of: post.category) { _, _ in markReviewed() }
    }

    private var languageName: String? {
        guard !post.detectedLanguage.isEmpty else { return nil }
        return Locale.current.localizedString(forLanguageCode: post.detectedLanguage)
    }

    @ViewBuilder
    private var readSection: some View {
        let hasContent = !post.caption.isEmpty || !post.ocrText.isEmpty || !post.englishText.isEmpty
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 16) {
                if !hasContent {
                    Text("Nothing was read from this post.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !post.caption.isEmpty {
                    readBlock("Caption", systemImage: "text.bubble", text: post.caption)
                }
                if !post.ocrText.isEmpty {
                    readBlock("Text in the image", systemImage: "text.viewfinder", text: post.ocrText)
                }
                if !post.englishText.isEmpty {
                    readBlock("English translation", systemImage: "character.bubble", text: post.englishText)
                }
                if let languageName {
                    Label("Language: \(languageName)", systemImage: "globe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        } label: {
            Label("What Déjà View read", systemImage: "eye")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private func readBlock(_ title: String, systemImage: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .surface(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Saving

    private func markReviewed() {
        if post.status == .needsReview { post.status = .processed; post.statusMessage = "" }
        save()
    }

    private func save() {
        do { try context.save(); errorMessage = nil } catch { context.rollback(); errorMessage = "Couldn't save changes. Please try again." }
    }
}
