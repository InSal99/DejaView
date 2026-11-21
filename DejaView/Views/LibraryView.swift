import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedPost.savedAt, order: .reverse) private var posts: [SavedPost]
    @State private var source: SourceFilter = .all
    @State private var category: PostCategory?
    @State private var showingAddLink = false
    @State private var postToDelete: SavedPost?
    @State private var errorMessage: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    enum SourceFilter: String, CaseIterable, Identifiable {
        case all = "All", posts = "Posts", screenshots = "Screenshots", links = "Links"
        var id: Self { self }
        func includes(_ kind: SourceKind) -> Bool {
            switch self {
            case .all: true
            case .posts: kind == .post
            case .screenshots: kind == .screenshot
            case .links: kind == .link
            }
        }
    }

    private var filteredPosts: [SavedPost] {
        posts.filter { source.includes($0.sourceKind) && (category == nil || $0.category == category) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if posts.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing saved yet", systemImage: "rectangle.on.rectangle")
                    } description: {
                        Text("You've seen it before. Now you can find it again. Share a post to Déjà View or paste a link.")
                    } actions: {
                        Button("Paste a link") { showingAddLink = true }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("Source", selection: $source) {
                                ForEach(SourceFilter.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)

                            ScrollView(.horizontal) {
                                HStack {
                                    Button("All") { category = nil }
                                        .buttonStyle(.borderedProminent)
                                        .tint(category == nil ? .accentColor : .secondary)
                                    ForEach(PostCategory.allCases.filter { candidate in posts.contains { $0.category == candidate } }, id: \.self) { candidate in
                                        Button { category = candidate } label: {
                                            CategoryChip(category: candidate, selected: category == candidate)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)

                            if filteredPosts.isEmpty {
                                ContentUnavailableView {
                                    Label("No matching posts", systemImage: "line.3.horizontal.decrease.circle")
                                } description: {
                                    Text("Try a different source or category.")
                                } actions: {
                                    Button("Clear filters") { source = .all; category = nil }
                                }
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                                    ForEach(filteredPosts) { post in
                                        NavigationLink { PostDetailView(post: post) } label: { PostCardView(post: post) }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                if let url = originalURL(for: post) {
                                                    Link(destination: url) { Label("Open original", systemImage: "arrow.up.right.square") }
                                                }
                                                Button("Delete", systemImage: "trash", role: .destructive) { postToDelete = post }
                                            }
                                    }
                                }
                            }
                            if let errorMessage {
                                Text(errorMessage).font(.footnote).foregroundStyle(.red)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Library")
            .safeAreaInset(edge: .top) {
                if let reason = AskService.unavailableReason {
                    ModelUnavailableBanner(reason: reason)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .toolbar {
                Button("Save a post", systemImage: "plus") { showingAddLink = true }
            }
            .sheet(isPresented: $showingAddLink) { AddLinkView() }
            .confirmationDialog("Delete this post?", isPresented: Binding(
                get: { postToDelete != nil },
                set: { if !$0 { postToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let post = postToDelete {
                        context.delete(post)
                        do { try context.save(); errorMessage = nil } catch { context.rollback(); errorMessage = "Couldn't delete this post. Please try again." }
                    }
                    postToDelete = nil
                }
            }
        }
    }

    private func originalURL(for post: SavedPost) -> URL? {
        guard let urlString = post.urlString, let url = URL(string: urlString),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
}
