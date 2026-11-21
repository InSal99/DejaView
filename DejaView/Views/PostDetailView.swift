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
    @State private var showNote = false
    @State private var note = ""
    @State private var errorMessage: String?

    private var description: String {
        post.summaryDescription.isEmpty ? post.summary : post.summaryDescription
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                VStack(alignment: .leading, spacing: 16) {
                    Text(post.displayTitle)
                        .font(.title2.bold())
                    Text("\(post.platform.displayName) · \(post.savedAt.staticSaved)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    summaryCard
                    keyPoints
                    tagChips

                    HStack {
                        categoryMenu
                        Spacer()
                    }

                    if let urlString = post.urlString, let url = URL(string: urlString), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                        Link(destination: url) { Label("Open original", systemImage: "arrow.up.right.square") }
                            .buttonStyle(.borderedProminent)
                    }

                    noteSection

                    DisclosureGroup("What Déjà View read") {
                        VStack(alignment: .leading, spacing: 12) {
                            if !post.caption.isEmpty { Text(post.caption) }
                            if !post.ocrText.isEmpty { Text(post.ocrText) }
                            if !post.englishText.isEmpty { Text(post.englishText) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    }
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            note = post.userNote
            showNote = !post.userNote.isEmpty
        }
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

    @ViewBuilder
    private var summaryCard: some View {
        if post.status == .pending || !description.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("AI Summary", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                Text(post.status == .pending ? "Processing…" : description)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private var keyPoints: some View {
        if !post.keyPoints.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Points").font(.headline)
                ForEach(post.keyPoints, id: \.self) { point in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                        Text(point)
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
                            .background(.quaternary, in: Capsule())
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

    @ViewBuilder
    private var noteSection: some View {
        if showNote {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Add a note…", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button("Save note") {
                    post.userNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !post.userNote.isEmpty { markReviewed() } else { save() }
                }
                .disabled(note == post.userNote)
            }
        } else {
            Button("Add note", systemImage: "plus") { showNote = true }
        }
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
