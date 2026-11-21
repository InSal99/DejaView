import SwiftUI
import SwiftData

struct PostDetailView: View {
    @Bindable var post: SavedPost
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(PostProcessor.self) private var processor
    @State private var showingDelete = false
    @State private var note = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PostImage(post: post).frame(height: 280).clipped().accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        CategoryChip(category: post.category)
                        Text(post.platform.displayName).foregroundStyle(.secondary)
                        Spacer()
                        Text(post.savedAt, style: .date).foregroundStyle(.secondary)
                    }.font(.caption)
                    Text(post.summary.isEmpty ? post.caption : post.summary).font(.title3)
                    if !post.tags.isEmpty {
                        Text(post.tags.map { "#\($0)" }.joined(separator: "  ")).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let urlString = post.urlString, let url = URL(string: urlString), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                        Link(destination: url) { Label("Open original", systemImage: "arrow.up.right.square") }.buttonStyle(.borderedProminent)
                    }
                    Picker("Category", selection: $post.category) {
                        ForEach(PostCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.symbol).tag(category)
                        }
                    }
                    .onChange(of: post.category) { _, _ in markReviewed() }
                    TextField("Add a note…", text: $note, axis: .vertical).textFieldStyle(.roundedBorder)
                    Button("Save note") {
                        post.userNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !post.userNote.isEmpty { markReviewed() } else { save() }
                    }.disabled(note == post.userNote)
                    DisclosureGroup("What Déjà View read") {
                        VStack(alignment: .leading, spacing: 12) {
                            if !post.caption.isEmpty { Text(post.caption) }
                            if !post.ocrText.isEmpty { Text(post.ocrText) }
                            if !post.englishText.isEmpty { Text(post.englishText) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                    }
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                }.padding(.horizontal, 16)
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { note = post.userNote }
        .toolbar {
            Menu("Post options", systemImage: "ellipsis.circle") {
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
        .confirmationDialog("Delete this post?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(post)
                do { try context.save(); dismiss() } catch { context.rollback(); errorMessage = "Couldn't delete this post. Please try again." }
            }
        }
    }

    private func markReviewed() {
        if post.status == .needsReview { post.status = .processed; post.statusMessage = "" }
        save()
    }

    private func save() {
        do { try context.save(); errorMessage = nil } catch { context.rollback(); errorMessage = "Couldn't save changes. Please try again." }
    }
}
